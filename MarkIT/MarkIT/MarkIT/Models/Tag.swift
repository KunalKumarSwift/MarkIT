import Foundation
import SwiftData

@Model
final class Tag {
    // CloudKit requires all non-optional properties to have declaration-level defaults.
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "📌"
    var colorHex: String = "#4A90E2"
    var createdAt: Date = Date()

    // nil = top-level parent tag
    var parent: Tag?

    // CloudKit requires all to-many relationships to be optional.
    // Use childrenList / linksList for non-optional access throughout the app.
    @Relationship(deleteRule: .cascade, inverse: \Tag.parent)
    var children: [Tag]?

    @Relationship(deleteRule: .cascade, inverse: \SavedLink.tag)
    var links: [SavedLink]?

    /// Non-optional accessor — safe to use in views and computed properties.
    var childrenList: [Tag] { children ?? [] }
    var linksList: [SavedLink] { links ?? [] }

    init(name: String, emoji: String, colorHex: String, parent: Tag? = nil) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.createdAt = Date()
        self.parent = parent
    }

    var isTopLevel: Bool { parent == nil }

    /// Total links across this tag and all its children
    var totalLinkCount: Int {
        linksList.count + childrenList.reduce(0) { $0 + $1.linksList.count }
    }
}
