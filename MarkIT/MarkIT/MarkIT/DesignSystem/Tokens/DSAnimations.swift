import SwiftUI

// MARK: - DSAnimation

/// Canonical animation presets.
enum DSAnimation {
    /// General-purpose spring — most state transitions.
    static var spring: Animation  { .spring(response: 0.4, dampingFraction: 0.75) }
    /// Snappier spring — selection feedback, toggles.
    static var snappy: Animation  { .spring(response: 0.3, dampingFraction: 0.8) }
    /// Bouncy spring — entrance of cards, preview card changes.
    static var bounce: Animation  { .spring(response: 0.35, dampingFraction: 0.6) }
    /// Fast ease-in-out — colour/opacity crossfades.
    static var quick: Animation   { .easeInOut(duration: 0.2) }
    /// Linear — progress bar fill.
    static var linear: Animation  { .linear(duration: 0.1) }
}

// MARK: - DSTransition

/// Canonical view transitions.
enum DSTransition {
    /// Scale + fade — card insertion/removal.
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.88).combined(with: .opacity)
    }
    /// Slide from top + fade on insert; fade on remove.
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        )
    }
    /// Simple opacity fade.
    static var fade: AnyTransition { .opacity }
}
