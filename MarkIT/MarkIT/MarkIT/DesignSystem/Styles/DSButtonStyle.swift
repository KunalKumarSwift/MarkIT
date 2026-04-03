import SwiftUI

// MARK: - DSPrimaryButtonStyle

/// Filled accent-colour button with a spring scale press effect.
///
/// Usage:
/// ```swift
/// Button("Save") { ... }
///     .buttonStyle(DSPrimaryButtonStyle())
/// ```
struct DSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DSFont.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, DSSpacing.xl)
            .padding(.vertical, DSSpacing.md)
            .background(DSColors.accent)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DSAnimation.snappy, value: configuration.isPressed)
    }
}

// MARK: - DSGhostButtonStyle

/// Bordered button with accent text, transparent background.
///
/// Usage:
/// ```swift
/// Button("Cancel") { ... }
///     .buttonStyle(DSGhostButtonStyle())
/// ```
struct DSGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DSFont.subheadline)
            .foregroundStyle(DSColors.accent)
            .padding(.horizontal, DSSpacing.xl)
            .padding(.vertical, DSSpacing.md)
            .background(
                Capsule().strokeBorder(DSColors.accent, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DSAnimation.snappy, value: configuration.isPressed)
    }
}
