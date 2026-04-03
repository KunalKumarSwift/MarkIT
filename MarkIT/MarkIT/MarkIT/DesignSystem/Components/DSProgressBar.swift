import SwiftUI

// MARK: - DSProgressBar

/// A slim animated progress bar, intended to sit at the top of the browser view.
/// Automatically hides when progress is 0 or 1.
///
/// Usage:
/// ```swift
/// DSProgressBar(progress: store.progress)
/// ```
struct DSProgressBar: View {
    /// Value from 0.0 to 1.0
    var progress: Double
    var tint: Color = DSColors.accent
    var height: CGFloat = 3

    private var isVisible: Bool {
        progress > 0.0 && progress < 1.0
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(tint.opacity(0.15))
                    .frame(height: height)

                // Fill
                Rectangle()
                    .fill(tint)
                    .frame(width: geo.size.width * progress, height: height)
                    .animation(DSAnimation.linear, value: progress)
            }
        }
        .frame(height: height)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(DSAnimation.quick, value: isVisible)
    }
}
