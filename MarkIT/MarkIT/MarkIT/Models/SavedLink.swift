import Foundation
import SwiftData

@Model
final class SavedLink {
    // CloudKit requires all non-optional properties to have declaration-level defaults.
    var id: UUID = UUID()
    var url: String = ""
    var title: String = ""
    var faviconURL: String?
    var savedAt: Date = Date()

    // CloudKit requires to-one relationships to be optional.
    // The tag this link belongs to (can be a parent or child tag).
    var tag: Tag?

    // Reading progress — manually updated by the user.
    // progressURL tracks the exact page they stopped at (may differ from url
    // when docs span many pages). progressPercent is 0–100, manually set.
    var progressURL: String?
    var progressNote: String?
    var progressPercent: Int = 0
    var lastProgressAt: Date?

    init(url: String, title: String, faviconURL: String? = nil, tag: Tag) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.faviconURL = faviconURL
        self.savedAt = Date()
        self.tag = tag
    }

    /// The domain extracted from the URL for display purposes.
    var domain: String {
        URL(string: url)?.host ?? url
    }

    /// True once the user has set any progress on this link.
    var hasProgress: Bool {
        progressPercent > 0 || progressURL != nil
    }

    /// The URL to resume reading from, falling back to the original URL.
    var resumeURL: String {
        progressURL ?? url
    }
}
