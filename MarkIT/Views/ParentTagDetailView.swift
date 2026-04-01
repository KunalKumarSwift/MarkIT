import SwiftUI
import SwiftData

struct ParentTagDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let tag: Tag

    @State private var showAddSubtag = false
    @State private var subtagToEdit: Tag?
    @State private var subtagToDelete: Tag?
    @State private var showDeleteSubtagAlert = false
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: DSSpacing.md),
        GridItem(.flexible(), spacing: DSSpacing.md),
    ]

    private var filteredDirectLinks: [SavedLink] {
        let sorted = tag.links.sorted { $0.savedAt > $1.savedAt }
        if searchText.isEmpty { return sorted }
        let query = searchText.lowercased()
        return sorted.filter {
            $0.title.lowercased().contains(query) || $0.url.lowercased().contains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                childrenSection
                if !tag.links.isEmpty || !searchText.isEmpty {
                    directLinksSection
                }
                if tag.children.isEmpty && tag.links.isEmpty {
                    DSEmptyState(
                        systemImage: "tray",
                        title: "Nothing Here Yet",
                        message: "Add subtags to organize your links,\nor save links directly to this tag."
                    )
                }
            }
            .padding(DSSpacing.lg)
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
        .sheet(item: $subtagToEdit) { subtag in
            AddTagSheet(mode: .edit(tag: subtag))
        }
        .alert(
            "Delete \"\(subtagToDelete?.name ?? "")\"?",
            isPresented: $showDeleteSubtagAlert,
            presenting: subtagToDelete
        ) { subtag in
            Button("Delete", role: .destructive) {
                modelContext.delete(subtag)
                subtagToDelete = nil
            }
            Button("Cancel", role: .cancel) { subtagToDelete = nil }
        } message: { subtag in
            Text("This will also delete all \(subtag.links.count) link(s) saved to this subtag.")
        }
    }

    // MARK: - Children Section

    @ViewBuilder
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack {
                Text("Subtags")
                    .font(DSFont.headline)
                    .foregroundStyle(DSColors.primary)
                Spacer()
                Button {
                    showAddSubtag = true
                } label: {
                    Label("Add Subtag", systemImage: "plus")
                        .font(DSFont.subheadline)
                }
            }

            if tag.children.isEmpty {
                Button {
                    showAddSubtag = true
                } label: {
                    HStack(spacing: DSSpacing.md) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.title2)
                            .foregroundStyle(DSColors.secondary)
                        Text("Add your first subtag")
                            .font(DSFont.subheadline)
                            .foregroundStyle(DSColors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DSSpacing.lg)
                    .background(DSColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                LazyVGrid(columns: columns, spacing: DSSpacing.md) {
                    ForEach(tag.children.sorted(by: { $0.createdAt < $1.createdAt })) { child in
                        NavigationLink(destination: ChildTagDetailView(tag: child)) {
                            TagCard(tag: child, isCompact: true)
                                .dsPressable()
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                subtagToEdit = child
                            } label: {
                                Label("Edit Subtag", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                subtagToDelete = child
                                showDeleteSubtagAlert = true
                            } label: {
                                Label("Delete Subtag", systemImage: "trash")
                            }
                        }
                        .transition(DSTransition.scaleAndFade)
                    }
                }
                .animation(DSAnimation.spring, value: tag.children.count)
            }
        }
    }

    // MARK: - Direct Links Section

    @ViewBuilder
    private var directLinksSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Saved Here")
                .font(DSFont.headline)
                .foregroundStyle(DSColors.primary)

            if filteredDirectLinks.isEmpty {
                Text("No links match your search.")
                    .font(DSFont.subheadline)
                    .foregroundStyle(DSColors.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(DSSpacing.lg)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredDirectLinks) { link in
                        NavigationLink(destination: BrowserView(initialURL: link.url)) {
                            LinkRow(link: link, tagColorHex: tag.colorHex)
                                .padding(.horizontal, DSSpacing.lg)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation(DSAnimation.spring) {
                                    modelContext.delete(link)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        if link.id != filteredDirectLinks.last?.id {
                            Divider()
                                .padding(.leading, DSSpacing.xxl + DSSpacing.md)
                        }
                    }
                }
                .background(DSColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
                .animation(DSAnimation.spring, value: filteredDirectLinks.count)
            }
        }
    }
}
