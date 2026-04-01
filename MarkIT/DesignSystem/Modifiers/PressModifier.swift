import SwiftUI

// MARK: - DSPressModifier

/// Adds a subtle scale-down effect when the view is pressed,
/// giving it a satisfying tactile feel without requiring a custom ButtonStyle.
///
/// Usage:
/// ```swift
/// myView.dsPressable()
/// ```
struct DSPressModifier: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(DSAnimation.snappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in state = true }
            )
    }
}

extension View {
    func dsPressable() -> some View {
        modifier(DSPressModifier())
    }
}
