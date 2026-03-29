import SwiftUI
import SwiftData

struct ChildTagDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let tag: Tag

    @State private var searchText = ""
    /// Set to trigger navigation to BrowserView starting at the original URL (not resume URL).
    @State private var openFromStartLink: SavedLink?

    private var filteredLinks: [SavedLink] {
        let sorted = tag.linksList.sorted { $0.savedAt > $1.savedAt }
        if searchText.isEmpty { return sorted }
        let query = searchText.lowercased()
        return sorted.filter {
            $0.title.lowercased().contains(query) || $0.url.lowercased().contains(query)
        }
    }

    var body: some View {
        Group {
            if tag.linksList.isEmpty {
                emptyState
            } else {
                linksList
            }
        }
        .navigationTitle("\(tag.emoji) \(tag.name)")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search links")
        // Programmatic navigation for "Open from Start" context menu action
        .navigationDestination(item: $openFromStartLink) { link in
            BrowserView(initialURL: link.url, link: link)
        }
    }

    // MARK: - Links List

    private var linksList: some View {
        List {
            ForEach(filteredLinks) { link in
                // Default tap: continue from where user left off (resumeURL = progressURL ?? url)
                NavigationLink(destination: BrowserView(initialURL: link.resumeURL, link: link)) {
                    LinkRow(link: link)
                }
                .contextMenu {
                    // Only show "Open from Start" when the user has saved a different progress URL
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
