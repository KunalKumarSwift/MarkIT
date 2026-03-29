import Foundation

/// Handles converting MarkIT data to/from the Netscape HTML Bookmarks format.
///
/// Why this format:
/// - Every major browser (Chrome, Safari, Firefox, Edge) can import it natively.
/// - The folder/nested-folder structure maps directly to parent tags and subtags.
/// - Custom MARKIT_* attributes carry progress data; browsers silently ignore them.
/// - .html files transfer over AirDrop, iMessage, Files, and email without issue.
struct BookmarkExporter {

    // MARK: - Export

    /// Generates a Netscape HTML Bookmarks file string from the selected tags.
    ///
    /// Selection rules:
    /// - If a parent tag is selected: its direct links are exported.
    /// - If a subtag is selected: its links are exported, nested under the parent.
    /// - If only subtags are selected (not the parent): those subtags appear at the top level.
    static func exportHTML(selectedTagIDs: Set<UUID>, parentTags: [Tag]) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())

        var lines: [String] = [
            "<!DOCTYPE NETSCAPE-Bookmark-file-1>",
            "<!-- MarkIT Export — \(dateStr) -->",
            "<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\">",
            "<TITLE>MarkIT Bookmarks</TITLE>",
            "<H1>MarkIT Bookmarks</H1>",
            "<DL><p>",
        ]

        for parent in parentTags.sorted(by: { $0.createdAt < $1.createdAt }) {
            let parentSelected = selectedTagIDs.contains(parent.id)
            let selectedChildren = parent.childrenList
                .filter { selectedTagIDs.contains($0.id) }
                .sorted(by: { $0.createdAt < $1.createdAt })

            if parentSelected {
                // Export parent folder with its direct links + any selected subtags
                lines.append(contentsOf: openFolder(parent, indent: 1))
                for link in parent.linksList.sorted(by: { $0.savedAt < $1.savedAt }) {
                    lines.append(renderLink(link, indent: 2))
                }
                for child in selectedChildren {
                    lines.append(contentsOf: openFolder(child, indent: 2))
                    for link in child.linksList.sorted(by: { $0.savedAt < $1.savedAt }) {
                        lines.append(renderLink(link, indent: 3))
                    }
                    lines.append(contentsOf: closeFolder( 2))
                }
                lines.append(contentsOf: closeFolder(1))

            } else if !selectedChildren.isEmpty {
                // Parent not selected — export chosen subtags as top-level folders
                for child in selectedChildren {
                    lines.append(contentsOf: openFolder(child, indent: 1))
                    for link in child.linksList.sorted(by: { $0.savedAt < $1.savedAt }) {
                        lines.append(renderLink(link, indent: 2))
                    }
                    lines.append(contentsOf: closeFolder(1))
                }
            }
        }

        lines.append("</DL>")
        return lines.joined(separator: "\n")
    }

    private static func openFolder(_ tag: Tag, indent: Int) -> [String] {
        let pad = padding(indent)
        let ts = Int(tag.createdAt.timeIntervalSince1970)
        return [
            "\(pad)<DT><H3 ADD_DATE=\"\(ts)\" MARKIT_EMOJI=\"\(tag.emoji)\" MARKIT_COLOR=\"\(tag.colorHex)\">\(escape(tag.name))</H3>",
            "\(pad)<DL><p>",
        ]
    }

    private static func closeFolder(_ indent: Int) -> [String] {
        ["\(padding(indent))</DL><p>"]
    }

    private static func renderLink(_ link: SavedLink, indent: Int) -> String {
        let pad = padding(indent)
        let ts = Int(link.savedAt.timeIntervalSince1970)
        var attrs = "HREF=\"\(escape(link.url))\" ADD_DATE=\"\(ts)\""
        if link.progressPercent > 0 {
            attrs += " MARKIT_PROGRESS=\"\(link.progressPercent)\""
        }
        if let pu = link.progressURL, !pu.isEmpty {
            attrs += " MARKIT_PROGRESS_URL=\"\(escape(pu))\""
        }
        if let note = link.progressNote, !note.isEmpty {
            attrs += " MARKIT_NOTE=\"\(escape(note))\""
        }
        let displayTitle = escape(link.title.isEmpty ? link.url : link.title)
        return "\(pad)<DT><A \(attrs)>\(displayTitle)</A>"
    }

    private static func padding(_ level: Int) -> String {
        String(repeating: "    ", count: level)
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - Import data types

    struct ImportedTag: Identifiable {
        let id = UUID()
        var name: String
        var emoji: String
        var colorHex: String
        var links: [ImportedLink]
        var children: [ImportedTag]

        var totalLinkCount: Int {
            links.count + children.reduce(0) { $0 + $1.links.count }
        }
    }

    struct ImportedLink {
        var url: String
        var title: String
        var savedAt: Date
        var progressPercent: Int
        var progressURL: String?
        var progressNote: String?
    }

    // MARK: - Import / Parse

    /// Parses a Netscape HTML Bookmarks file into a tree of ImportedTag values.
    ///
    /// Strategy: maintain a stack. Each `<H3>` sets a pendingFolder; the next
    /// `<DL>` pushes it. Each `</DL>` pops and attaches to the parent.
    static func parseHTML(_ html: String) -> [ImportedTag] {
        // Sentinel root node accumulates top-level items
        var stack: [StackFrame] = [StackFrame(name: "__root__", emoji: "📌", color: "#4A90E2")]
        var pendingFolder: (name: String, emoji: String, color: String)?

        for rawLine in html.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            let lower = line.lowercased()

            if lower.contains("<h3") {
                let name = tagContent(line, tag: "H3") ?? "Untitled"
                let emoji = attr(line, name: "MARKIT_EMOJI") ?? "📌"
                let color = attr(line, name: "MARKIT_COLOR") ?? "#4A90E2"
                pendingFolder = (name, emoji, color)

            } else if lower.hasPrefix("<dl") {
                if let f = pendingFolder {
                    stack.append(StackFrame(name: f.name, emoji: f.emoji, color: f.color))
                    pendingFolder = nil
                }
                // else: root <DL> — no push needed

            } else if lower.hasPrefix("</dl") {
                if stack.count > 1 {
                    let frame = stack.removeLast()
                    let tag = ImportedTag(
                        name: frame.name,
                        emoji: frame.emoji,
                        colorHex: frame.color,
                        links: frame.links,
                        children: frame.children
                    )
                    stack[stack.count - 1].children.append(tag)
                }

            } else if lower.contains("<dt>") && lower.contains("<a ") {
                if let link = parseLink(line) {
                    stack[stack.count - 1].links.append(link)
                }
            }
        }

        let root = stack[0]
        var result = root.children

        // Wrap any top-level orphan links in a default folder
        if !root.links.isEmpty {
            let orphan = ImportedTag(
                name: "Imported",
                emoji: "📥",
                colorHex: "#4A90E2",
                links: root.links,
                children: []
            )
            result.insert(orphan, at: 0)
        }

        return result
    }

    private static func parseLink(_ line: String) -> ImportedLink? {
        guard let url = attr(line, name: "HREF"), !url.isEmpty else { return nil }
        let title = tagContent(line, tag: "A") ?? url
        let savedAt: Date = {
            guard let s = attr(line, name: "ADD_DATE"), let ts = TimeInterval(s) else { return Date() }
            return Date(timeIntervalSince1970: ts)
        }()
        return ImportedLink(
            url: url,
            title: title,
            savedAt: savedAt,
            progressPercent: Int(attr(line, name: "MARKIT_PROGRESS") ?? "0") ?? 0,
            progressURL: attr(line, name: "MARKIT_PROGRESS_URL").flatMap { $0.isEmpty ? nil : $0 },
            progressNote: attr(line, name: "MARKIT_NOTE").flatMap { $0.isEmpty ? nil : $0 }
        )
    }

    /// Extracts the text content between `<TAG ...>` and `</TAG>` (case-insensitive).
    private static func tagContent(_ line: String, tag: String) -> String? {
        let lower = line.lowercased()
        let openTag = "<\(tag.lowercased())"
        let closeTag = "</\(tag.lowercased())>"
        guard let openRange = lower.range(of: openTag),
              let closeRange = lower.range(of: closeTag),
              let gtRange = lower[openRange.upperBound...].range(of: ">") else { return nil }

        let start = line.index(gtRange.upperBound, offsetBy: 0)
        let end   = line.index(closeRange.lowerBound, offsetBy: 0)
        guard start <= end else { return nil }
        return String(line[start..<end]).unescaped
    }

    /// Extracts the value of a named attribute like `NAME="value"` (case-insensitive).
    private static func attr(_ line: String, name: String) -> String? {
        guard let range = line.range(of: "\(name)=\"", options: .caseInsensitive) else { return nil }
        let after = line[range.upperBound...]
        guard let end = after.firstIndex(of: "\"") else { return nil }
        return String(after[..<end]).unescaped
    }

    // Mutable stack frame used during parsing
    private class StackFrame {
        let name: String
        let emoji: String
        let color: String
        var links: [ImportedLink] = []
        var children: [ImportedTag] = []

        init(name: String, emoji: String, color: String) {
            self.name = name
            self.emoji = emoji
            self.color = color
        }
    }
}

private extension String {
    var unescaped: String {
        self.replacingOccurrences(of: "&amp;",  with: "&")
            .replacingOccurrences(of: "&lt;",   with: "<")
            .replacingOccurrences(of: "&gt;",   with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;",  with: "'")
    }
}
