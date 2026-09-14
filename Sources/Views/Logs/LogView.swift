import SwiftUI
import AppKit

public struct LogView: View {
    @ObservedObject var logger = ActivityLogger.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity Log")
                        .font(.system(size: 16, weight: .semibold))
                    Text("\(logger.entries.count) events captured")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Copy Log") {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(logger.exportText(), forType: .string)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Export...") {
                    exportLog()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Clear") {
                    logger.clear()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Table / Log list
            if logger.entries.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "terminal")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No activity logged yet")
                        .font(.system(size: 14, weight: .medium))
                    Text("Process executions and diagnostic logs will appear here in real time.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(logger.entries) { entry in
                                HStack(alignment: .top, spacing: 10) {
                                    Text(entry.formattedTimestamp)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 85, alignment: .leading)

                                    Text("[\(entry.process)]")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundColor(entry.isError ? .red : .accentColor)
                                        .frame(width: 65, alignment: .leading)

                                    Text(entry.message)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(entry.isError ? .red : .primary)
                                        .textSelection(.enabled)

                                    Spacer()
                                }
                                .padding(.vertical, 2)
                                .id(entry.id)
                            }
                        }
                        .padding(14)
                    }
                    .onChange(of: logger.entries.count) { _ in
                        if let lastId = logger.entries.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .background(Color(nsColor: .textBackgroundColor))
            }
        }
    }

    private func exportLog() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "mediafetch-activity.log"
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            try? logger.exportText().write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
