import Foundation

public struct TrimRange: Sendable, Equatable {
    public var isEnabled: Bool = false
    public var startTime: Double = 0
    public var endTime: Double = 0
    public var totalDuration: Double = 0

    public init(isEnabled: Bool = false, startTime: Double = 0, endTime: Double = 0, totalDuration: Double = 0) {
        self.isEnabled = isEnabled
        self.startTime = startTime
        self.endTime = endTime > 0 ? min(endTime, totalDuration) : totalDuration
        self.totalDuration = totalDuration
    }

    public var duration: Double {
        max(0, endTime - startTime)
    }

    public var startTimeString: String {
        TimeFormatter.format(seconds: startTime)
    }

    public var endTimeString: String {
        TimeFormatter.format(seconds: endTime)
    }

    public var durationString: String {
        TimeFormatter.format(seconds: duration)
    }

    public var isValid: Bool {
        guard isEnabled else { return true }
        guard startTime >= 0 else { return false }
        guard endTime > startTime else { return false }
        if totalDuration > 0 {
            guard endTime <= (totalDuration + 0.5) else { return false }
        }
        return true
    }

    public var validationErrorMessage: String? {
        guard isEnabled else { return nil }
        if startTime < 0 {
            return "Start time cannot be negative."
        }
        if startTime >= endTime {
            return "Start time must be before end time."
        }
        if totalDuration > 0 && endTime > (totalDuration + 0.5) {
            return "End time cannot exceed total duration."
        }
        return nil
    }

    public mutating func reset() {
        startTime = 0
        endTime = totalDuration
    }
}
