import SwiftUI

// MARK: - DSGlassModifier

/// Applies a frosted-glass background using `.ultraThinMaterial` with a subtle
/// tinted overlay. Adapts automatically to light and dark mode.
///
/// Usage:
/// ```swift
/// myView.dsGlass()
/// ```
struct DSGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                Color(.systemBackground).opacity(0.08)
            )
    }
}

extension View {
    func dsGlass() -> some View {
        modifier(DSGlassModifier())
    }
}
