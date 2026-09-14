import SwiftUI

public struct MediaInfoCard: View {
    let mediaInfo: MediaInfo
    let estimatedSizeString: String

    public init(mediaInfo: MediaInfo, estimatedSizeString: String) {
        self.mediaInfo = mediaInfo
        self.estimatedSizeString = estimatedSizeString
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                if let thumbStr = mediaInfo.thumbnailUrl, let thumbURL = URL(string: thumbStr) {
                    AsyncImage(url: thumbURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(nsColor: .controlBackgroundColor))
                                .overlay(ProgressView().controlSize(.small))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fit)
                        case .failure:
                            Rectangle()
                                .fill(Color(nsColor: .controlBackgroundColor))
                                .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay(Image(systemName: "film").foregroundColor(.secondary))
                }

                // Duration badge
                if mediaInfo.duration > 0 {
                    Text(TimeFormatter.format(seconds: mediaInfo.duration))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(4)
                        .padding(6)
                }
            }
            .frame(width: 220, height: 124)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )

            // Metadata column
            VStack(alignment: .leading, spacing: 6) {
                Text(mediaInfo.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 11))
                    Text(mediaInfo.channel)
                        .font(.system(size: 12))

                    if let date = mediaInfo.uploadDate, date.count == 8 {
                        Text("•")
                        Text(formatUploadDate(date))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.secondary)

                Spacer()

                // Badges row
                HStack(spacing: 6) {
                    if mediaInfo.maxResolutionHeight > 0 {
                        MetadataBadge(text: "\(mediaInfo.maxResolutionHeight)p", icon: "arrow.up.right.video")
                    }
                    if mediaInfo.maxFPS > 0 {
                        MetadataBadge(text: "\(Int(mediaInfo.maxFPS)) fps", icon: "speedometer")
                    }
                    MetadataBadge(text: mediaInfo.primaryVideoCodec, icon: "film")
                    MetadataBadge(text: estimatedSizeString, icon: "scalemass")
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    private func formatUploadDate(_ raw: String) -> String {
        // Formatted from YYYYMMDD to YYYY-MM-DD
        let year = raw.prefix(4)
        let month = raw.dropFirst(4).prefix(2)
        let day = raw.suffix(2)
        return "\(year)-\(month)-\(day)"
    }
}

private struct MetadataBadge: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(nsColor: .windowBackgroundColor))
        .foregroundColor(.secondary)
        .cornerRadius(4)
    }
}
