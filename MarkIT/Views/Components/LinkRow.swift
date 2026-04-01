import SwiftUI

struct LinkRow: View {
    let link: SavedLink
    /// Optional accent colour from the tag — shown as a leading colour bar.
    var tagColorHex: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var faviconURL: URL? {
        guard let domain = URL(string: link.url)?.host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64")
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: link.savedAt, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 0) {
            // Leading accent colour bar
            if let hex = tagColorHex {
                RoundedRectangle(cornerRadius: DSRadius.sm)
                    .fill(Color(hex: hex))
                    .frame(width: 4)
                    .padding(.trailing, DSSpacing.md)
            }

            // Favicon
            Group {
                AsyncImage(url: faviconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .transition(DSTransition.fade)
                    case .failure:
                        Image(systemName: "globe")
                            .foregroundStyle(DSColors.secondary)
                    case .empty:
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DSColors.secondaryBackground)
                            .dsShimmer()
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .frame(width: 24, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .animation(DSAnimation.quick, value: faviconURL)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(link.title.isEmpty ? link.url : link.title)
                    .font(DSFont.subheadline)
                    .foregroundStyle(DSColors.primary)
                    .lineLimit(2)

                HStack(spacing: DSSpacing.xs) {
                    Text(link.domain)
                        .font(DSFont.caption)
                        .foregroundStyle(DSColors.secondary)

                    Text("·")
                        .font(DSFont.caption)
                        .foregroundStyle(DSColors.tertiary)

                    Text(formattedDate)
                        .font(DSFont.caption)
                        .foregroundStyle(DSColors.secondary)
                }
            }
            .padding(.leading, DSSpacing.md)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(DSColors.tertiary)
        }
        .padding(.vertical, DSSpacing.sm)
    }
}
