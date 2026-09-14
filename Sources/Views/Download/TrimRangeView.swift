import SwiftUI

public struct TrimRangeView: View {
    @Binding var trimRange: TrimRange
    let totalDuration: Double

    @State private var startHours: Int = 0
    @State private var startMinutes: Int = 0
    @State private var startSeconds: Int = 0

    @State private var endHours: Int = 0
    @State private var endMinutes: Int = 0
    @State private var endSeconds: Int = 0

    public init(trimRange: Binding<TrimRange>, totalDuration: Double) {
        self._trimRange = trimRange
        self.totalDuration = totalDuration
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Checkbox toggle with clear subtitle
            HStack(spacing: 8) {
                Toggle(isOn: $trimRange.isEnabled) {
                    HStack(spacing: 6) {
                        Text("Trim Media")
                            .font(.system(size: 13, weight: .semibold))
                        Text("(Download a specific section)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
                .onChange(of: trimRange.isEnabled) { _, isEnabled in
                    if isEnabled {
                        if trimRange.endTime <= 0 && totalDuration > 0 {
                            trimRange.endTime = totalDuration
                        }
                        syncPickersFromRange()
                    }
                }

                Spacer()

                if trimRange.isEnabled {
                    Button("Reset Range") {
                        trimRange.startTime = 0
                        trimRange.endTime = totalDuration > 0 ? totalDuration : 60
                        syncPickersFromRange()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if trimRange.isEnabled {
                VStack(alignment: .leading, spacing: 14) {
                    // Start and End Time Pickers
                    HStack(spacing: 20) {
                        // Start Time Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Start Time")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)

                            TimePickerRow(
                                hours: $startHours,
                                minutes: $startMinutes,
                                seconds: $startSeconds,
                                maxTotalSeconds: max(0, Int(trimRange.endTime) - 1),
                                totalDurationSeconds: Int(totalDuration),
                                onChange: {
                                    let newStart = Double(startHours * 3600 + startMinutes * 60 + startSeconds)
                                    trimRange.startTime = min(newStart, max(0, trimRange.endTime - 1))
                                }
                            )

                            // Quick step buttons
                            HStack(spacing: 4) {
                                StepButton(label: "-10s") { adjustStart(by: -10) }
                                StepButton(label: "-1m") { adjustStart(by: -60) }
                                StepButton(label: "+10s") { adjustStart(by: 10) }
                                StepButton(label: "+1m") { adjustStart(by: 60) }
                                StepButton(label: "+5m") { adjustStart(by: 300) }
                            }
                        }

                        // End Time Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("End Time")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)

                            TimePickerRow(
                                hours: $endHours,
                                minutes: $endMinutes,
                                seconds: $endSeconds,
                                maxTotalSeconds: Int(totalDuration > 0 ? totalDuration : 86400),
                                totalDurationSeconds: Int(totalDuration),
                                onChange: {
                                    let newEnd = Double(endHours * 3600 + endMinutes * 60 + endSeconds)
                                    let maxLimit = totalDuration > 0 ? totalDuration : 86400
                                    trimRange.endTime = min(maxLimit, max(newEnd, trimRange.startTime + 1))
                                }
                            )

                            // Quick step buttons
                            HStack(spacing: 4) {
                                StepButton(label: "-5m") { adjustEnd(by: -300) }
                                StepButton(label: "-1m") { adjustEnd(by: -60) }
                                StepButton(label: "-10s") { adjustEnd(by: -10) }
                                StepButton(label: "+10s") { adjustEnd(by: 10) }
                                StepButton(label: "+1m") { adjustEnd(by: 60) }
                            }
                        }

                        // Clip Duration Readout
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Clip Duration")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)

                            Text(TimeFormatter.format(seconds: trimRange.duration))
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(.accentColor)
                                .padding(.top, 2)

                            if totalDuration > 0 {
                                let pct = Int((trimRange.duration / totalDuration) * 100)
                                Text("\(pct)% of total")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }

                    // Interactive Timeline Visualizer & Sliders
                    if totalDuration > 0 {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Timeline")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Total: \(TimeFormatter.format(seconds: totalDuration))")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            // Visual timeline bar
                            GeometryReader { geo in
                                let w = geo.size.width
                                let startFraction = CGFloat(trimRange.startTime / totalDuration)
                                let endFraction = CGFloat(trimRange.endTime / totalDuration)

                                ZStack(alignment: .leading) {
                                    // Background track
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(nsColor: .separatorColor).opacity(0.3))
                                        .frame(height: 12)

                                    // Selected range highlight
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.accentColor.opacity(0.4))
                                        .frame(width: max(2, w * (endFraction - startFraction)), height: 12)
                                        .offset(x: w * startFraction)
                                }
                            }
                            .frame(height: 12)

                            // Range sliders
                            VStack(spacing: 6) {
                                HStack {
                                    Text("Start:")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 45, alignment: .leading)
                                    Slider(
                                        value: $trimRange.startTime,
                                        in: 0...max(0.1, trimRange.endTime - 1)
                                    ) { _ in
                                        syncPickersFromRange()
                                    }
                                    Text(trimRange.startTimeString)
                                        .font(.system(size: 11, design: .monospaced))
                                        .frame(width: 65, alignment: .trailing)
                                }

                                HStack {
                                    Text("End:  ")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 45, alignment: .leading)
                                    Slider(
                                        value: $trimRange.endTime,
                                        in: min(totalDuration, trimRange.startTime + 1)...totalDuration
                                    ) { _ in
                                        syncPickersFromRange()
                                    }
                                    Text(trimRange.endTimeString)
                                        .font(.system(size: 11, design: .monospaced))
                                        .frame(width: 65, alignment: .trailing)
                                }
                            }
                        }
                    }

                    // Validation warning if any
                    if let err = trimRange.validationErrorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text(err)
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(14)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
            }
        }
        .onAppear {
            if trimRange.endTime <= 0 && totalDuration > 0 {
                trimRange.endTime = totalDuration
            }
            syncPickersFromRange()
        }
        .onChange(of: totalDuration) { _, newDuration in
            if newDuration > 0 && trimRange.endTime <= 0 {
                trimRange.endTime = newDuration
            }
            syncPickersFromRange()
        }
    }

    private func adjustStart(by delta: Double) {
        let newStart = max(0, min(trimRange.endTime - 1, trimRange.startTime + delta))
        trimRange.startTime = newStart
        syncPickersFromRange()
    }

    private func adjustEnd(by delta: Double) {
        let maxLimit = totalDuration > 0 ? totalDuration : 86400
        let newEnd = min(maxLimit, max(trimRange.startTime + 1, trimRange.endTime + delta))
        trimRange.endTime = newEnd
        syncPickersFromRange()
    }

    private func syncPickersFromRange() {
        let totalStart = Int(trimRange.startTime)
        startHours = totalStart / 3600
        startMinutes = (totalStart % 3600) / 60
        startSeconds = totalStart % 60

        let totalEnd = Int(trimRange.endTime)
        endHours = totalEnd / 3600
        endMinutes = (totalEnd % 3600) / 60
        endSeconds = totalEnd % 60
    }
}

/// A row of hour:minute:second steppers — each spinner is individually adjustable
private struct TimePickerRow: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    let maxTotalSeconds: Int
    let totalDurationSeconds: Int
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            // Hours
            if totalDurationSeconds >= 3600 {
                NumberStepper(value: $hours, range: 0...maxHours, label: "h", onChange: clampAndNotify)
                Text(":")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // Minutes
            NumberStepper(value: $minutes, range: 0...59, label: "m", onChange: clampAndNotify)

            Text(":")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)

            // Seconds
            NumberStepper(value: $seconds, range: 0...59, label: "s", onChange: clampAndNotify)
        }
    }

    private var maxHours: Int {
        max(0, totalDurationSeconds / 3600)
    }

    private func clampAndNotify() {
        let totalSecs = hours * 3600 + minutes * 60 + seconds
        if totalSecs > maxTotalSeconds && maxTotalSeconds > 0 {
            let clamped = maxTotalSeconds
            hours = clamped / 3600
            minutes = (clamped % 3600) / 60
            seconds = clamped % 60
        }
        onChange()
    }
}

/// A compact numeric stepper with inline text field and up/down buttons
private struct NumberStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String
    let onChange: () -> Void

    @State private var text: String = ""

    var body: some View {
        HStack(spacing: 2) {
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .frame(width: 36)
                .multilineTextAlignment(.center)
                .onSubmit {
                    if let n = Int(text) {
                        value = min(range.upperBound, max(range.lowerBound, n))
                        text = String(format: "%02d", value)
                        onChange()
                    } else {
                        text = String(format: "%02d", value)
                    }
                }
                .onAppear {
                    text = String(format: "%02d", value)
                }
                .onChange(of: value) { _, newVal in
                    text = String(format: "%02d", newVal)
                }

            VStack(spacing: 0) {
                Button {
                    if value < range.upperBound {
                        value += 1
                        onChange()
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 7, weight: .bold))
                        .frame(width: 14, height: 11)
                }
                .buttonStyle(.plain)

                Button {
                    if value > range.lowerBound {
                        value -= 1
                        onChange()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .frame(width: 14, height: 11)
                }
                .buttonStyle(.plain)
            }

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

/// Compact step button used in the trim range view
private struct StepButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(label) {
            action()
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
        .font(.system(size: 10))
    }
}
