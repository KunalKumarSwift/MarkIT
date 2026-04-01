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
                DSEmptyState(
                    systemImage: "bookmark.slash",
                    title: "No Saved Links",
                    message: "Browse the web and tap Save to\nadd links to this tag."
                )
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
                    LinkRow(link: link, tagColorHex: tag.colorHex)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation(DSAnimation.spring) {
                            modelContext.delete(link)
                        }
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
        .animation(DSAnimation.spring, value: filteredLinks.count)
    }
}
