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

    // When a parent tag is deleted, its children are also deleted (cascade).
    // To promote children to top-level, manually set child.parent = nil before deleting the parent.
    @Relationship(deleteRule: .cascade, inverse: \Tag.parent)
    var children: [Tag] = []

    @Relationship(deleteRule: .cascade, inverse: \SavedLink.tag)
    var links: [SavedLink] = []

    init(name: String, emoji: String, colorHex: String, parent: Tag? = nil) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.createdAt = Date()
        self.parent = parent
        self.children = []
        self.links = []
    }

    var isTopLevel: Bool { parent == nil }

    /// Total links across this tag and all its children
    var totalLinkCount: Int {
        links.count + children.reduce(0) { $0 + $1.links.count }
    }
}
