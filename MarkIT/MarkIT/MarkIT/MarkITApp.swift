import SwiftUI
import SwiftData

@main
struct MarkITApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Tag.self, SavedLink.self])
        do {
            // Attempt to use a CloudKit-backed store for iCloud sync.
            // Requires the iCloud + CloudKit capabilities in the Xcode target
            // and a matching container identifier (e.g. iCloud.com.yourteam.MarkIT).
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            container = try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // Fall back to local-only storage when CloudKit is unavailable
            // (simulator, user not signed in to iCloud, etc.).
            // cloudKitDatabase: .none is required — without it, SwiftData still
            // tries to use NSPersistentCloudKitContainer when CloudKit entitlements
            // are present, which fails in the same way.
            do {
                let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
                container = try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
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
