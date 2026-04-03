import SwiftUI

// MARK: - DSEmptyState

/// A reusable empty state view with an animated entrance.
/// The icon scales up from 0.5, followed by the text fading in.
///
/// Usage:
/// ```swift
/// DSEmptyState(
///     systemImage: "tag.circle",
///     title: "No Tags Yet",
///     message: "Create your first tag to start organizing.",
///     actionTitle: "Create Tag",
///     action: { showAddTag = true }
/// )
/// ```
struct DSEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @State private var iconAppeared = false
    @State private var textAppeared = false

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundStyle(DSColors.accent.opacity(0.7))
                .scaleEffect(iconAppeared ? 1.0 : 0.5)
                .opacity(iconAppeared ? 1.0 : 0.0)

            VStack(spacing: DSSpacing.sm) {
                Text(title)
                    .font(DSFont.title2)
                    .foregroundStyle(DSColors.primary)

                Text(message)
                    .font(DSFont.subheadline)
                    .foregroundStyle(DSColors.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(textAppeared ? 1.0 : 0.0)
            .offset(y: textAppeared ? 0 : 8)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(DSPrimaryButtonStyle())
                    .opacity(textAppeared ? 1.0 : 0.0)
            }
        }
        .padding(DSSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(DSAnimation.bounce) {
                iconAppeared = true
            }
            withAnimation(DSAnimation.spring.delay(0.12)) {
                textAppeared = true
            }
        }
    }
}
