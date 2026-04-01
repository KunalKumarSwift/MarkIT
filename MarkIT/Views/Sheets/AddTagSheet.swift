import SwiftUI
import SwiftData

// MARK: - Mode

enum AddTagMode {
    case newParent
    case newChild(parent: Tag)
    case edit(tag: Tag)
}

// MARK: - AddTagSheet

struct AddTagSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let mode: AddTagMode

    @State private var name: String = ""
    @State private var selectedEmoji: String = "📌"
    @State private var selectedColor: String = TagColors.default
    @State private var previewScale: CGFloat = 1.0

    private var title: String {
        switch mode {
        case .newParent: return "New Tag"
        case .newChild:  return "New Subtag"
        case .edit:      return "Edit Tag"
        }
    }

    private var parentTag: Tag? {
        if case .newChild(let parent) = mode { return parent }
        if case .edit(let tag) = mode { return tag.parent }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    previewCard
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                Section("Tag Name") {
                    TextField("e.g. Swift Study", text: $name)
                }

                Section("Emoji") {
                    emojiGrid
                }

                Section("Color") {
                    colorGrid
                }

                if let parent = parentTag {
                    Section {
                        HStack {
                            Text("Parent Tag")
                                .foregroundStyle(DSColors.secondary)
                            Spacer()
                            Text("\(parent.emoji) \(parent.name)")
                                .foregroundStyle(DSColors.primary)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { loadExistingValues() }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        let tagColor = DSTagColor(hex: selectedColor, colorScheme: colorScheme)
        return HStack {
            Spacer()
            VStack(spacing: DSSpacing.sm) {
                Text(selectedEmoji)
                    .font(.largeTitle)
                Text(name.isEmpty ? "Tag Name" : name)
                    .font(DSFont.headline)
                    .foregroundStyle(tagColor.foreground)
            }
            .frame(width: 140, height: 90)
            .background(tagColor.background)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.1 : 0), lineWidth: 1)
            )
            .shadow(
                color: tagColor.background.opacity(DSShadow.elevated.color),
                radius: DSShadow.elevated.radius,
                x: DSShadow.elevated.x,
                y: DSShadow.elevated.y
            )
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
                    .background(
                        selectedEmoji == emoji
                            ? DSColors.accent.opacity(0.15)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                            .strokeBorder(
                                selectedEmoji == emoji ? DSColors.accent : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .scaleEffect(selectedEmoji == emoji ? 1.08 : 1.0)
                    .animation(DSAnimation.snappy, value: selectedEmoji)
                    .onTapGesture {
                        withAnimation(DSAnimation.snappy) {
                            selectedEmoji = emoji
                        }
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
                    .overlay(
                        Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .scaleEffect(selectedColor == hex ? 1.0 : 0.01)
                            .opacity(selectedColor == hex ? 1.0 : 0.0)
                            .animation(DSAnimation.snappy, value: selectedColor)
                    )
                    .scaleEffect(selectedColor == hex ? 1.1 : 1.0)
                    .animation(DSAnimation.snappy, value: selectedColor)
                    .onTapGesture {
                        withAnimation(DSAnimation.snappy) {
                            selectedColor = hex
                        }
                        bouncePreview()
                    }
            }
        }
        .padding(.vertical, DSSpacing.xs)
    }

    // MARK: - Helpers

    private func bouncePreview() {
        previewScale = 0.92
        withAnimation(DSAnimation.bounce) {
            previewScale = 1.0
        }
    }

    private func loadExistingValues() {
        switch mode {
        case .newParent:
            break
        case .newChild(let parent):
            selectedColor = parent.colorHex
        case .edit(let tag):
            name = tag.name
            selectedEmoji = tag.emoji
            selectedColor = tag.colorHex
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        switch mode {
        case .newParent:
            modelContext.insert(Tag(name: trimmedName, emoji: selectedEmoji, colorHex: selectedColor))
        case .newChild(let parent):
            modelContext.insert(Tag(name: trimmedName, emoji: selectedEmoji, colorHex: selectedColor, parent: parent))
        case .edit(let tag):
            tag.name = trimmedName
            tag.emoji = selectedEmoji
            tag.colorHex = selectedColor
        }
        dismiss()
    }
}
