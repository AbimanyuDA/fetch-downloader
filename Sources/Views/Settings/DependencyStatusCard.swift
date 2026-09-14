import SwiftUI

public struct DependencyStatusCard: View {
    let status: DependencyStatus
    var onUpdate: (() -> Void)? = nil
    var isUpdating: Bool = false

    public init(status: DependencyStatus, onUpdate: (() -> Void)? = nil, isUpdating: Bool = false) {
        self.status = status
        self.onUpdate = onUpdate
        self.isUpdating = isUpdating
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.isAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(status.isAvailable ? .green : .orange)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(status.name)
                        .font(.system(size: 13, weight: .semibold))

                    if let ver = status.version {
                        Text("v\(ver)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                if let path = status.path {
                    Text(path)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Component missing. Click to install or verify installation.")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            if let onUpdate = onUpdate {
                Button {
                    onUpdate()
                } label: {
                    if isUpdating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(status.isAvailable ? "Check Update" : "Install")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isUpdating)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}
