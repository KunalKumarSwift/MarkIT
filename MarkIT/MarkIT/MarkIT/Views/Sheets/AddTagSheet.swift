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

    let mode: AddTagMode

    @State private var name: String = ""
    @State private var selectedEmoji: String = "📌"
    @State private var selectedColor: String = TagColors.default

    private var title: String {
        switch mode {
        case .newParent: return "New Tag"
        case .newChild: return "New Subtag"
        case .edit: return "Edit Tag"
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
                // Preview
                Section {
                    previewCard
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                // Name
                Section("Tag Name") {
                    TextField("e.g. Swift Study", text: $name)
                }

                // Emoji picker
                Section("Emoji") {
                    emojiGrid
                }

                // Color picker
                Section("Color") {
                    colorGrid
                }

                if let parent = parentTag {
                    Section {
                        HStack {
                            Text("Parent Tag")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(parent.emoji) \(parent.name)")
                                .foregroundStyle(.primary)
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
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Text(selectedEmoji)
                    .font(.largeTitle)
                Text(name.isEmpty ? "Tag Name" : name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .frame(width: 140, height: 90)
            .background(Color(hex: selectedColor))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(hex: selectedColor).opacity(0.35), radius: 6, x: 0, y: 3)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Emoji Grid

    private var emojiGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(TagEmojis.all, id: \.self) { emoji in
                Text(emoji)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedEmoji == emoji ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture { selectedEmoji = emoji }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Color Grid

    private var colorGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(TagColors.all, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .opacity(selectedColor == hex ? 1 : 0)
                    )
                    .onTapGesture { selectedColor = hex }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func loadExistingValues() {
        switch mode {
        case .newParent:
            break
        case .newChild(let parent):
            // Inherit parent colour by default
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
            let tag = Tag(name: trimmedName, emoji: selectedEmoji, colorHex: selectedColor)
            modelContext.insert(tag)

        case .newChild(let parent):
            let tag = Tag(name: trimmedName, emoji: selectedEmoji, colorHex: selectedColor, parent: parent)
            modelContext.insert(tag)

        case .edit(let tag):
            tag.name = trimmedName
            tag.emoji = selectedEmoji
            tag.colorHex = selectedColor
        }

        dismiss()
    }
}
