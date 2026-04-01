import SwiftUI
import SwiftData

struct AddGoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var selectedEmoji: String = "🎯"
    @State private var selectedColor: String = TagColors.default
    @State private var selectedPeriod: GoalPeriod = .day
    @State private var previewScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            Form {
                // Preview tile
                Section {
                    previewTile
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                Section("Goal Title") {
                    TextField("e.g. Morning Meditation", text: $title)
                }

                Section("Subtitle / Category") {
                    TextField("e.g. 15 Minutes • Habit", text: $subtitle)
                }

                Section("Period") {
                    DSSegmentedPicker(
                        options: GoalPeriod.allCases,
                        selection: $selectedPeriod
                    ) { period in
                        Text(period.label)
                    }
                    .listRowInsets(.init(top: DSSpacing.sm, leading: DSSpacing.lg,
                                        bottom: DSSpacing.sm, trailing: DSSpacing.lg))
                }

                Section("Emoji") {
                    emojiGrid
                }

                Section("Colour") {
                    colorGrid
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Preview Tile

    private var previewTile: some View {
        HStack {
            Spacer()
            HStack(spacing: DSSpacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                        .fill(Color(hex: selectedColor).opacity(0.18))
                        .frame(width: 56, height: 56)
                    Text(selectedEmoji)
                        .font(.title)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.isEmpty ? "Goal Title" : title)
                        .font(DSFont.headline)
                        .foregroundStyle(DSColors.primary)
                    Text(subtitle.isEmpty ? "Subtitle" : subtitle)
                        .font(DSFont.caption)
                        .foregroundStyle(DSColors.secondary)
                }
                Spacer()
            }
            .padding(DSSpacing.lg)
            .background(DSColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
            .scaleEffect(previewScale)
            Spacer()
        }
        .padding(.vertical, DSSpacing.sm)
    }

    // MARK: - Emoji Grid

    private var emojiGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)
        return LazyVGrid(columns: columns, spacing: DSSpacing.sm) {
            ForEach(TagEmojis.all, id: \.self) { emoji in
                Text(emoji)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(selectedEmoji == emoji ? DSColors.accent.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                            .strokeBorder(selectedEmoji == emoji ? DSColors.accent : Color.clear, lineWidth: 2)
                    )
                    .scaleEffect(selectedEmoji == emoji ? 1.08 : 1.0)
                    .animation(DSAnimation.snappy, value: selectedEmoji)
                    .onTapGesture {
                        withAnimation(DSAnimation.snappy) { selectedEmoji = emoji }
                        bouncePreview()
                    }
            }
        }
        .padding(.vertical, DSSpacing.xs)
    }

    // MARK: - Color Grid

    private var colorGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: DSSpacing.sm), count: 6)
        return LazyVGrid(columns: columns, spacing: DSSpacing.sm) {
            ForEach(TagColors.all, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.caption).fontWeight(.bold)
                            .foregroundStyle(.white)
                            .scaleEffect(selectedColor == hex ? 1.0 : 0.01)
                            .opacity(selectedColor == hex ? 1.0 : 0.0)
                            .animation(DSAnimation.snappy, value: selectedColor)
                    )
                    .scaleEffect(selectedColor == hex ? 1.1 : 1.0)
                    .animation(DSAnimation.snappy, value: selectedColor)
                    .onTapGesture {
                        withAnimation(DSAnimation.snappy) { selectedColor = hex }
                        bouncePreview()
                    }
            }
        }
        .padding(.vertical, DSSpacing.xs)
    }

    // MARK: - Helpers

    private func bouncePreview() {
        previewScale = 0.92
        withAnimation(DSAnimation.bounce) { previewScale = 1.0 }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let goal = Goal(
            title: trimmed,
            emoji: selectedEmoji,
            subtitle: subtitle.trimmingCharacters(in: .whitespaces),
            colorHex: selectedColor,
            period: selectedPeriod
        )
        modelContext.insert(goal)
        dismiss()
    }
}
