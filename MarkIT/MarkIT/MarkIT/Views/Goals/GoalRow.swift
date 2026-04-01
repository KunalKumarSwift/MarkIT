import SwiftUI

struct GoalRow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let goal: Goal
    /// The reference date used to determine completion (default = today)
    var date: Date = Date()

    @State private var isCompleted: Bool = false
    @State private var checkScale: CGFloat = 1.0

    private var tileColor: Color {
        Color(hex: goal.colorHex).opacity(0.15)
    }

    var body: some View {
        HStack(spacing: DSSpacing.lg) {
            // Emoji icon tile
            ZStack {
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .fill(tileColor)
                    .frame(width: 48, height: 48)
                Text(goal.emoji)
                    .font(.title2)
            }

            // Title + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(DSFont.headline)
                    .foregroundStyle(DSColors.primary)
                    .strikethrough(isCompleted, color: DSColors.secondary)

                if !goal.subtitle.isEmpty {
                    Text(goal.subtitle)
                        .font(DSFont.caption)
                        .foregroundStyle(DSColors.secondary)
                }
            }

            Spacer()

            // Circular checkbox
            Button {
                toggleCompletion()
            } label: {
                ZStack {
                    Circle()
                        .fill(isCompleted ? DSColors.accent : Color.clear)
                        .frame(width: 32, height: 32)

                    Circle()
                        .strokeBorder(
                            isCompleted ? DSColors.accent : DSColors.separator,
                            lineWidth: 2
                        )
                        .frame(width: 32, height: 32)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(DSTransition.scaleAndFade)
                    }
                }
                .scaleEffect(checkScale)
            }
            .buttonStyle(.plain)
        }
        .padding(DSSpacing.lg)
        .background(DSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        .dsPressable()
        .onAppear { isCompleted = goal.isCompleted(on: date) }
        .onChange(of: date) { isCompleted = goal.isCompleted(on: date) }
    }

    // MARK: - Actions

    private func toggleCompletion() {
        // Bounce the checkmark
        checkScale = 0.8
        withAnimation(DSAnimation.bounce) { checkScale = 1.0 }

        withAnimation(DSAnimation.snappy) {
            let result = goal.toggleCompletion(on: date)
            isCompleted = (result != nil)
            // If a new completion was added, insert it so SwiftData tracks it
            if let newCompletion = result {
                modelContext.insert(newCompletion)
            }
        }
    }
}
