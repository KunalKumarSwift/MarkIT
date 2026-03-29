import SwiftUI
import SwiftData

struct SaveToTagSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let url: String
    let title: String

    @Query(
        filter: #Predicate<Tag> { $0.parent == nil },
        sort: \Tag.createdAt,
        order: .forward
    )
    private var parentTags: [Tag]

    @State private var selectedParent: Tag?
    @State private var selectedChild: Tag?
    @State private var saved = false

    private var selectedTag: Tag? {
        selectedChild ?? selectedParent
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Page info header
                pageInfoHeader
                    .padding()

                Divider()

                // Tag selection
                if parentTags.isEmpty {
                    noTagsState
                } else {
                    tagSelectionList
                }

                Spacer()

                // Save button
                saveButton
                    .padding()
            }
            .navigationTitle("Save to Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Page Info Header

    private var pageInfoHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? "Untitled Page" : title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    // MARK: - Tag Selection List

    private var tagSelectionList: some View {
        List {
            ForEach(parentTags) { parent in
                Section {
                    // Parent row
                    parentRow(parent)

                    // Child rows (expanded when parent is selected)
                    if selectedParent?.id == parent.id {
                        let children = parent.children.sorted { $0.createdAt < $1.createdAt }
                        ForEach(children) { child in
                            childRow(child)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: selectedParent?.id)
    }

    // MARK: - Parent Row

    private func parentRow(_ parent: Tag) -> some View {
        Button {
            withAnimation {
                if selectedParent?.id == parent.id {
                    // Deselect
                    selectedParent = nil
                    selectedChild = nil
                } else {
                    selectedParent = parent
                    selectedChild = nil
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Color dot + emoji
                ZStack {
                    Circle()
                        .fill(Color(hex: parent.colorHex))
                        .frame(width: 36, height: 36)
                    Text(parent.emoji)
                        .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(parent.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if !parent.children.isEmpty {
                        Text("\(parent.children.count) subtag(s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Selection indicator or expand chevron
                HStack(spacing: 8) {
                    if selectedParent?.id == parent.id && selectedChild == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.accentColor)
                    }

                    if !parent.children.isEmpty {
                        Image(systemName: selectedParent?.id == parent.id ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Child Row

    private func childRow(_ child: Tag) -> some View {
        Button {
            withAnimation {
                selectedChild = (selectedChild?.id == child.id) ? nil : child
            }
        } label: {
            HStack(spacing: 12) {
                // Indent + color dot + emoji
                Color.clear.frame(width: 8)

                ZStack {
                    Circle()
                        .fill(Color(hex: child.colorHex))
                        .frame(width: 30, height: 30)
                    Text(child.emoji)
                        .font(.caption)
                }

                Text(child.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                if selectedChild?.id == child.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - No Tags State

    private var noTagsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("No Tags Yet")
                    .font(.headline)
                Text("Create a tag first from the Library tab.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveLink()
        } label: {
            Group {
                if let tag = selectedTag {
                    Label("Save to \(tag.emoji) \(tag.name)", systemImage: "bookmark.fill")
                } else {
                    Label("Select a Tag to Save", systemImage: "bookmark")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedTag != nil ? Color.accentColor : Color(.tertiarySystemFill))
            .foregroundStyle(selectedTag != nil ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedTag == nil)
    }

    // MARK: - Actions

    private func saveLink() {
        guard let tag = selectedTag else { return }

        let faviconURL: String?
        if let host = URL(string: url)?.host {
            faviconURL = "https://www.google.com/s2/favicons?domain=\(host)&sz=64"
        } else {
            faviconURL = nil
        }

        let link = SavedLink(
            url: url,
            title: title.isEmpty ? url : title,
            faviconURL: faviconURL,
            tag: tag
        )
        modelContext.insert(link)
        dismiss()
    }
}
