import SwiftUI

// MARK: - DSCardModifier

/// Applies a coloured card background, rounded corners, and a subtle shadow.
///
/// Usage:
/// ```swift
/// myView.modifier(DSCardModifier(color: tagColor.background, shadowColor: tagColor.background))
/// ```
struct DSCardModifier: ViewModifier {
    let color: Color
    /// The colour used for the drop shadow (typically the card colour at reduced opacity).
    var shadowColor: Color

    init(color: Color, shadowColor: Color? = nil) {
        self.color = color
        self.shadowColor = shadowColor ?? color
    }

    func body(content: Content) -> some View {
        let shadow = DSShadow.card
        content
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
            .shadow(
                color: shadowColor.opacity(shadow.color),
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

extension View {
    func dsCard(color: Color, shadowColor: Color? = nil) -> some View {
        modifier(DSCardModifier(color: color, shadowColor: shadowColor))
    }
}
