import Foundation
import SwiftData

@Model
final class SavedLink {
    var id: UUID
    var url: String
    var title: String
    var faviconURL: String?
    var savedAt: Date

    // The tag this link belongs to (can be a parent or child tag)
    var tag: Tag

    init(url: String, title: String, faviconURL: String? = nil, tag: Tag) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.faviconURL = faviconURL
        self.savedAt = Date()
        self.tag = tag
    }

    /// The domain extracted from the URL for display purposes
    var domain: String {
        URL(string: url)?.host ?? url
    }
}
