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
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        Group {
            if tags.isEmpty {
                emptyState
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tag.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Tags Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create your first tag to start organizing\nyour study links.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddTag = true
            } label: {
                Label("Create Tag", systemImage: "plus")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    // MARK: - Tag Grid

    private var tagGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(tags) { tag in
                    NavigationLink(destination: ParentTagDetailView(tag: tag)) {
                        TagCard(tag: tag)
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
                }
            }
            .padding(16)
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
