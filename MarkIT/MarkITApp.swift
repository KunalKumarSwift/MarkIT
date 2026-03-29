import SwiftUI
import SwiftData

@main
struct MarkITApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Tag.self, SavedLink.self])
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
            }

            NavigationStack {
                BrowserView()
            }
            .tabItem {
                Label("Browser", systemImage: "safari.fill")
            }
        }
    }
}
