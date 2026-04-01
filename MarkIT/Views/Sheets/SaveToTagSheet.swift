import SwiftUI
import SwiftData

struct SaveToTagSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

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

    private var selectedTag: Tag? { selectedChild ?? selectedParent }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                pageInfoHeader
                    .padding(DSSpacing.lg)
                    .dsGlass()
                    .overlay(alignment: .bottom) { Divider() }

                if parentTags.isEmpty {
                    DSEmptyState(
                        systemImage: "tag.slash",
                        title: "No Tags Yet",
                        message: "Create a tag first from the Library tab."
                    )
                } else {
                    tagSelectionList
                }

                Spacer(minLength: 0)

                saveButton
                    .padding(DSSpacing.lg)
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
        HStack(spacing: DSSpacing.md) {
            Image(systemName: "doc.richtext")
                .font(.title2)
                .foregroundStyle(DSColors.secondary)
                .frame(width: 40, height: 40)
                .background(DSColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? "Untitled Page" : title)
                    .font(DSFont.subheadline)
                    .foregroundStyle(DSColors.primary)
                    .lineLimit(1)

                Text(url)
                    .font(DSFont.caption)
                    .foregroundStyle(DSColors.secondary)
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
                    parentRow(parent)

                    if selectedParent?.id == parent.id {
                        let children = parent.children.sorted { $0.createdAt < $1.createdAt }
                        ForEach(children) { child in
                            childRow(child)
                                .transition(DSTransition.slideAndFade)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(DSAnimation.spring, value: selectedParent?.id)
    }

    // MARK: - Parent Row

    private func parentRow(_ parent: Tag) -> some View {
        let tagColor = DSTagColor(hex: parent.colorHex, colorScheme: colorScheme)
        return Button {
            withAnimation(DSAnimation.spring) {
                if selectedParent?.id == parent.id {
                    selectedParent = nil
                    selectedChild = nil
                } else {
                    selectedParent = parent
                    selectedChild = nil
                }
            }
        } label: {
            HStack(spacing: DSSpacing.md) {
                ZStack {
                    Circle()
                        .fill(tagColor.background)
                        .frame(width: 36, height: 36)
                    Text(parent.emoji)
                        .font(DSFont.subheadline)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(parent.name)
                        .font(DSFont.subheadline)
                        .foregroundStyle(DSColors.primary)

                    if !parent.children.isEmpty {
                        Text("\(parent.children.count) subtag(s)")
                            .font(DSFont.caption)
                            .foregroundStyle(DSColors.secondary)
                    }
                }

                Spacer()

                HStack(spacing: DSSpacing.sm) {
                    if selectedParent?.id == parent.id && selectedChild == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DSColors.accent)
                            .transition(DSTransition.scaleAndFade)
                    }
                    if !parent.children.isEmpty {
                        Image(systemName: selectedParent?.id == parent.id ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(DSColors.secondary)
                            .animation(DSAnimation.snappy, value: selectedParent?.id)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Child Row

    private func childRow(_ child: Tag) -> some View {
        let tagColor = DSTagColor(hex: child.colorHex, colorScheme: colorScheme)
        return Button {
            withAnimation(DSAnimation.snappy) {
                selectedChild = (selectedChild?.id == child.id) ? nil : child
            }
        } label: {
            HStack(spacing: DSSpacing.md) {
                Color.clear.frame(width: DSSpacing.lg)

                ZStack {
                    Circle()
                        .fill(tagColor.background)
                        .frame(width: 30, height: 30)
                    Text(child.emoji)
                        .font(DSFont.caption)
                }

                Text(child.name)
                    .font(DSFont.subheadline)
                    .foregroundStyle(DSColors.primary)

                Spacer()

                if selectedChild?.id == child.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DSColors.accent)
                        .transition(DSTransition.scaleAndFade)
                }
            }
        }
        .buttonStyle(.plain)
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
            .font(DSFont.headline)
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.lg)
            .background(
                selectedTag != nil ? DSColors.accent : Color(.tertiarySystemFill)
            )
            .foregroundStyle(selectedTag != nil ? .white : DSColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
            .animation(DSAnimation.quick, value: selectedTag != nil)
        }
        .disabled(selectedTag == nil)
    }

    // MARK: - Actions

    private func saveLink() {
        guard let tag = selectedTag else { return }
        let faviconURL: String? = URL(string: url)?.host.map {
            "https://www.google.com/s2/favicons?domain=\($0)&sz=64"
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
