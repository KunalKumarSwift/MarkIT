import SwiftUI

struct TagCard: View {
    let tag: Tag
    var isCompact: Bool = false

    private var cardColor: Color {
        Color(hex: tag.colorHex)
    }

    private var subtitle: String {
        if tag.isTopLevel {
            let childCount = tag.children.count
            let linkCount = tag.totalLinkCount
            var parts: [String] = []
            if childCount > 0 {
                parts.append("\(childCount) \(childCount == 1 ? "subtag" : "subtags")")
            }
            if linkCount > 0 {
                parts.append("\(linkCount) \(linkCount == 1 ? "link" : "links")")
            }
            return parts.isEmpty ? "Empty" : parts.joined(separator: " · ")
        } else {
            let count = tag.links.count
            return "\(count) \(count == 1 ? "link" : "links")"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 4 : 8) {
            Text(tag.emoji)
                .font(isCompact ? .title2 : .largeTitle)

            Text(tag.name)
                .font(isCompact ? .subheadline : .headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(subtitle)
                .font(isCompact ? .caption2 : .caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isCompact ? 12 : 16)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 12 : 16))
        .shadow(color: cardColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
