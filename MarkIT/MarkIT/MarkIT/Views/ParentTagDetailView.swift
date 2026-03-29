import SwiftUI
import SwiftData

struct ParentTagDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let tag: Tag

    @State private var showAddSubtag = false
    @State private var subtahToEdit: Tag?
    @State private var subtahToDelete: Tag?
    @State private var showDeleteSubtagAlert = false
    @State private var searchText = ""
    @State private var openFromStartLink: SavedLink?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var filteredDirectLinks: [SavedLink] {
        if searchText.isEmpty {
            return tag.linksList.sorted { $0.savedAt > $1.savedAt }
        }
        let query = searchText.lowercased()
        return tag.linksList
            .filter { $0.title.lowercased().contains(query) || $0.url.lowercased().contains(query) }
            .sorted { $0.savedAt > $1.savedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Child tag grid
                if !tag.childrenList.isEmpty || true {
                    childrenSection
                }

                // Direct links section
                if !tag.linksList.isEmpty || !searchText.isEmpty {
                    directLinksSection
                }

                // Empty state when everything is empty
                if tag.childrenList.isEmpty && tag.linksList.isEmpty {
                    emptyState
                }
            }
            .padding(16)
        }
        .navigationTitle("\(tag.emoji) \(tag.name)")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search links")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSubtag = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showAddSubtag) {
            AddTagSheet(mode: .newChild(parent: tag))
        }
        .sheet(item: $subtahToEdit) { subtag in
            AddTagSheet(mode: .edit(tag: subtag))
        }
        .navigationDestination(item: $openFromStartLink) { link in
            BrowserView(initialURL: link.url, link: link)
        }
        .alert(
            "Delete \"\(subtahToDelete?.name ?? "")\"?",
            isPresented: $showDeleteSubtagAlert,
            presenting: subtahToDelete
        ) { subtag in
            Button("Delete", role: .destructive) {
                modelContext.delete(subtag)
                subtahToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                subtahToDelete = nil
            }
        } message: { subtag in
            Text("This will also delete all \(subtag.linksList.count) link(s) saved to this subtag.")
        }
    }

    // MARK: - Children Section

    @ViewBuilder
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Subtags")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    showAddSubtag = true
                } label: {
                    Label("Add Subtag", systemImage: "plus")
                        .font(.subheadline)
                }
            }

            if tag.childrenList.isEmpty {
                Button {
                    showAddSubtag = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.dashed")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Add your first subtag")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(tag.childrenList.sorted(by: { $0.createdAt < $1.createdAt })) { child in
                        NavigationLink(destination: ChildTagDetailView(tag: child)) {
                            TagCard(tag: child, isCompact: true)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                subtahToEdit = child
                            } label: {
                                Label("Edit Subtag", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                subtahToDelete = child
                                showDeleteSubtagAlert = true
                            } label: {
                                Label("Delete Subtag", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Direct Links Section

    @ViewBuilder
    private var directLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Here")
                .font(.headline)

            if filteredDirectLinks.isEmpty {
                Text("No links match your search.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredDirectLinks) { link in
                        // Default tap: continue from where user left off
                        NavigationLink(destination: BrowserView(initialURL: link.resumeURL, link: link)) {
                            LinkRow(link: link)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if link.hasProgress {
                                Button {
                                    openFromStartLink = link
                                } label: {
                                    Label("Open from Start", systemImage: "arrow.counterclockwise")
                                }

                                Button(role: .destructive) {
                                    link.progressURL = nil
                                    link.progressNote = nil
                                    link.progressPercent = 0
                                    link.lastProgressAt = nil
                                } label: {
                                    Label("Reset Progress", systemImage: "arrow.uturn.backward")
                                }

                                Divider()
                            }

                            Button(role: .destructive) {
                                modelContext.delete(link)
                            } label: {
                                Label("Delete Link", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(link)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        if link.id != filteredDirectLinks.last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("Nothing Here Yet")
                    .font(.headline)

                Text("Add subtags to organize your links,\nor save links directly to this tag.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
