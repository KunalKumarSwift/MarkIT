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
    @State private var showAddTagSheet = false
    @State private var addTagMode: AddTagMode = .newParent

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
            .sheet(isPresented: $showAddTagSheet) {
                AddTagSheet(mode: addTagMode)
            }
            .onChange(of: parentTags.count) { oldCount, newCount in
                // Auto-select newly created parent tag
                if newCount > oldCount {
                    selectedParent = parentTags.last
                    selectedChild = nil
                }
            }
            .onChange(of: selectedParent?.childrenList.count) { oldCount, newCount in
                // Auto-select newly created subtag
                guard let newCount, let oldCount, newCount > oldCount else { return }
                selectedChild = selectedParent?.childrenList
                    .sorted { $0.createdAt < $1.createdAt }
                    .last
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

                    // Child rows + add subtag (expanded when parent is selected)
                    if selectedParent?.id == parent.id {
                        let children = parent.childrenList.sorted { $0.createdAt < $1.createdAt }
                        ForEach(children) { child in
                            childRow(child)
                        }
                        addSubtagButton(for: parent)
                    }
                }
            }

            // New Tag row at the bottom
            Section {
                newTagButton
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

                    if !parent.childrenList.isEmpty {
                        Text("\(parent.childrenList.count) subtag(s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Selection indicator + expand chevron
                HStack(spacing: 8) {
                    if selectedParent?.id == parent.id && selectedChild == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }

                    Image(systemName: selectedParent?.id == parent.id ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Subtag Button

    private func addSubtagButton(for parent: Tag) -> some View {
        Button {
            addTagMode = .newChild(parent: parent)
            showAddTagSheet = true
        } label: {
            HStack(spacing: 12) {
                Color.clear.frame(width: 8)

                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30, height: 30)

                Text("New Subtag")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - New Tag Button

    private var newTagButton: some View {
        Button {
            addTagMode = .newParent
            showAddTagSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)

                Text("New Tag")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)

                Spacer()
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
                Text("Create your first tag to start saving.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                addTagMode = .newParent
                showAddTagSheet = true
            } label: {
                Label("Create Tag", systemImage: "plus")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
