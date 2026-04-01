import SwiftUI

// MARK: - ShimmerModifier

/// Overlays an animated diagonal gradient to signal a loading/skeleton state.
///
/// Usage:
/// ```swift
/// Rectangle()
///     .frame(width: 24, height: 24)
///     .dsShimmer(isActive: isLoading)
/// ```
struct ShimmerModifier: ViewModifier {
    var isActive: Bool = true
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geo in
                        let gradient = LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Color.white.opacity(0.45), location: 0.5),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: .init(x: phase, y: 0),
                            endPoint: .init(x: phase + 1, y: 1)
                        )
                        gradient
                            .frame(width: geo.size.width * 3)
                            .offset(x: geo.size.width * phase)
                    }
                    .clipped()
                )
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.4).repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func dsShimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
