import SwiftUI
import SwiftData

struct ChildTagDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let tag: Tag

    @State private var searchText = ""

    private var filteredLinks: [SavedLink] {
        let sorted = tag.links.sorted { $0.savedAt > $1.savedAt }
        if searchText.isEmpty { return sorted }
        let query = searchText.lowercased()
        return sorted.filter {
            $0.title.lowercased().contains(query) || $0.url.lowercased().contains(query)
        }
    }

    var body: some View {
        Group {
            if tag.links.isEmpty {
                emptyState
            } else {
                linksList
            }
        }
        .navigationTitle("\(tag.emoji) \(tag.name)")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search links")
    }

    // MARK: - Links List

    private var linksList: some View {
        List {
            ForEach(filteredLinks) { link in
                NavigationLink(destination: BrowserView(initialURL: link.url)) {
                    LinkRow(link: link)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(link)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            if filteredLinks.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("No Saved Links")
                    .font(.headline)

                Text("Browse the web and tap Save to add links\nto this tag.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
