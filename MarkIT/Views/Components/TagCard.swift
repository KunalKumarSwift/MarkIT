import SwiftUI

struct TagCard: View {
    let tag: Tag
    var isCompact: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    private var tagColor: DSTagColor {
        DSTagColor(hex: tag.colorHex, colorScheme: colorScheme)
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
        VStack(alignment: .leading, spacing: isCompact ? DSSpacing.xs : DSSpacing.sm) {
            Text(tag.emoji)
                .font(isCompact ? .title2 : .largeTitle)

            Text(tag.name)
                .font(isCompact ? DSFont.subheadline : DSFont.headline)
                .foregroundStyle(tagColor.foreground)
                .lineLimit(2)

            Text(subtitle)
                .font(isCompact ? DSFont.caption2 : DSFont.caption)
                .foregroundStyle(tagColor.foreground.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isCompact ? DSSpacing.md : DSSpacing.lg)
        // Adaptive card background with dark-mode inner border for depth
        .background(tagColor.background)
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? DSRadius.md : DSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? DSRadius.md : DSRadius.lg, style: .continuous)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.1 : 0), lineWidth: 1)
        )
        .shadow(
            color: tagColor.background.opacity(DSShadow.card.color),
            radius: DSShadow.card.radius,
            x: DSShadow.card.x,
            y: DSShadow.card.y
        )
        // Entrance animation — driven by the parent view stagger, not by this view
        .scaleEffect(appeared ? 1.0 : 0.88)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(DSAnimation.bounce) {
                appeared = true
            }
        }
    }
}
