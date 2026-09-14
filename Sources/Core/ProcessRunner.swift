import Foundation

public struct ProcessResult: Sendable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String

    public var isSuccess: Bool {
        exitCode == 0
    }
}

public enum ProcessError: LocalizedError, Sendable {
    case binaryNotFound(String)
    case executionFailed(exitCode: Int32, stderr: String)
    case cancelled
    case timedOut

    public var errorDescription: String? {
        switch self {
        case .binaryNotFound(let name):
            return "Component not found: \(name). Please ensure it is installed or configured in Settings."
        case .executionFailed(let code, let err):
            let cleanErr = err.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleanErr.isEmpty ? "Process terminated with exit code \(code)." : cleanErr
        case .cancelled:
            return "The process was cancelled by the user."
        case .timedOut:
            return "The operation timed out."
        }
    }
}

public actor ProcessRunner {
    private var activeProcess: Process?

    public init() {}

    /// Runs an executable and returns all output at once
    public func run(
        executableURL: URL,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment: [String: String]? = nil
    ) async throws -> ProcessResult {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        if let currentDirectory = currentDirectory {
            process.currentDirectoryURL = currentDirectory
        }

        var env = ProcessInfo.processInfo.environment
        // Ensure standard search paths for tools
        let defaultPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        if let existing = env["PATH"] {
            env["PATH"] = "\(existing):\(defaultPath)"
        } else {
            env["PATH"] = defaultPath
        }
        if let extraEnv = environment {
            for (k, v) in extraEnv {
                env[k] = v
            }
        }
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        self.activeProcess = process

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                var stdoutData = Data()
                var stderrData = Data()

                let stdoutHandle = stdoutPipe.fileHandleForReading
                let stderrHandle = stderrPipe.fileHandleForReading

                let dispatchGroup = DispatchGroup()

                dispatchGroup.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    stdoutData = stdoutHandle.readDataToEndOfFile()
                    dispatchGroup.leave()
                }

                dispatchGroup.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    stderrData = stderrHandle.readDataToEndOfFile()
                    dispatchGroup.leave()
                }

                process.terminationHandler = { proc in
                    dispatchGroup.wait()
                    let code = proc.terminationStatus
                    let outStr = String(data: stdoutData, encoding: .utf8) ?? ""
                    let errStr = String(data: stderrData, encoding: .utf8) ?? ""
                    continuation.resume(returning: ProcessResult(exitCode: code, stdout: outStr, stderr: errStr))
                }

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            process.terminate()
        }
    }

    /// Runs an executable and streams output lines in real time
    public func stream(
        executableURL: URL,
        arguments: [String],
        currentDirectory: URL? = nil,
        onLine: @escaping @Sendable (String) -> Void
    ) async throws -> Int32 {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        if let currentDirectory = currentDirectory {
            process.currentDirectoryURL = currentDirectory
        }

        var env = ProcessInfo.processInfo.environment
        let defaultPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = "\(env["PATH"] ?? ""):\(defaultPath)"
        // Force unbuffered output for yt-dlp / python
        env["PYTHONUNBUFFERED"] = "1"
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe // merge stdout and stderr for progress tracking

        self.activeProcess = process

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let handle = pipe.fileHandleForReading
                var buffer = Data()

                handle.readabilityHandler = { fileHandle in
                    let availableData = fileHandle.availableData
                    guard !availableData.isEmpty else { return }

                    buffer.append(availableData)

                    // Find line endings (\n or \r used by terminal progress bars)
                    while let range = buffer.range(of: Data([0x0A])) ?? buffer.range(of: Data([0x0D])) {
                        let lineData = buffer.subdata(in: 0..<range.lowerBound)
                        buffer.removeSubrange(0..<range.upperBound)
                        if let line = String(data: lineData, encoding: .utf8) {
                            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                onLine(trimmed)
                            }
                        }
                    }
                }

                process.terminationHandler = { proc in
                    handle.readabilityHandler = nil
                    if !buffer.isEmpty, let leftover = String(data: buffer, encoding: .utf8) {
                        let trimmed = leftover.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onLine(trimmed)
                        }
                    }
                    continuation.resume(returning: proc.terminationStatus)
                }

                do {
                    try process.run()
                } catch {
                    handle.readabilityHandler = nil
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            process.terminate()
        }
    }

    public func cancel() {
        activeProcess?.terminate()
        activeProcess = nil
    }
}
