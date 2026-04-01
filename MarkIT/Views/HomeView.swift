import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<Tag> { $0.parent == nil },
        sort: \Tag.createdAt,
        order: .forward
    )
    private var tags: [Tag]

    @State private var showAddTag = false
    @State private var tagToEdit: Tag?
    @State private var tagToDelete: Tag?
    @State private var showDeleteOptions = false

    private let columns = [
        GridItem(.flexible(), spacing: DSSpacing.md),
        GridItem(.flexible(), spacing: DSSpacing.md),
    ]

    var body: some View {
        Group {
            if tags.isEmpty {
                DSEmptyState(
                    systemImage: "tag.circle",
                    title: "No Tags Yet",
                    message: "Create your first tag to start\norganizing your study links.",
                    actionTitle: "Create Tag",
                    action: { showAddTag = true }
                )
            } else {
                tagGrid
            }
        }
        .navigationTitle("MarkIT")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddTag = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showAddTag) {
            AddTagSheet(mode: .newParent)
        }
        .sheet(item: $tagToEdit) { tag in
            AddTagSheet(mode: .edit(tag: tag))
        }
        .confirmationDialog(
            deleteDialogTitle,
            isPresented: $showDeleteOptions,
            titleVisibility: .visible
        ) {
            deleteDialogButtons
        }
    }

    // MARK: - Tag Grid

    private var tagGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: DSSpacing.md) {
                ForEach(Array(tags.enumerated()), id: \.element.id) { index, tag in
                    NavigationLink(destination: ParentTagDetailView(tag: tag)) {
                        TagCard(tag: tag)
                            .dsPressable()
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            tagToEdit = tag
                        } label: {
                            Label("Edit Tag", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            tagToDelete = tag
                            showDeleteOptions = true
                        } label: {
                            Label("Delete Tag", systemImage: "trash")
                        }
                    }
                    .transition(DSTransition.scaleAndFade)
                }
            }
            .padding(DSSpacing.lg)
            .animation(DSAnimation.spring, value: tags.count)
        }
    }

    // MARK: - Delete Dialog

    private var deleteDialogTitle: String {
        guard let tag = tagToDelete else { return "Delete Tag" }
        if tag.children.isEmpty {
            return "Delete \"\(tag.name)\"?"
        }
        return "Delete \"\(tag.name)\" and its \(tag.children.count) subtag(s)?"
    }

    @ViewBuilder
    private var deleteDialogButtons: some View {
        if let tag = tagToDelete {
            if !tag.children.isEmpty {
                Button("Delete All Children", role: .destructive) {
                    deleteTag(tag, promoteChildren: false)
                }
                Button("Promote Children to Top-Level", role: .destructive) {
                    deleteTag(tag, promoteChildren: true)
                }
            } else {
                Button("Delete", role: .destructive) {
                    deleteTag(tag, promoteChildren: false)
                }
            }
            Button("Cancel", role: .cancel) {
                tagToDelete = nil
            }
        }
    }

    // MARK: - Actions

    private func deleteTag(_ tag: Tag, promoteChildren: Bool) {
        if promoteChildren {
            for child in tag.children {
                child.parent = nil
            }
        }
        modelContext.delete(tag)
        tagToDelete = nil
    }
}
