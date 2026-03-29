import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - MoreView

struct MoreView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<Tag> { $0.parent == nil },
        sort: \Tag.createdAt,
        order: .forward
    )
    private var parentTags: [Tag]

    // Export state
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var exportFileURL: URL?
    @State private var showShareSheet = false

    // Import state
    @State private var showImportPicker = false
    @State private var importPreview: [BookmarkExporter.ImportedTag] = []
    @State private var showImportPreview = false
    @State private var importErrorMessage: String?
    @State private var showImportError = false

    // MARK: - Derived

    private var allTagIDs: Set<UUID> {
        var ids = Set<UUID>()
        for tag in parentTags {
            ids.insert(tag.id)
            for child in tag.childrenList { ids.insert(child.id) }
        }
        return ids
    }

    private var isAllSelected: Bool {
        !allTagIDs.isEmpty && allTagIDs.isSubset(of: selectedTagIDs)
    }

    private var selectedLinkCount: Int {
        var count = 0
        for tag in parentTags {
            if selectedTagIDs.contains(tag.id) { count += tag.linksList.count }
            for child in tag.childrenList {
                if selectedTagIDs.contains(child.id) { count += child.linksList.count }
            }
        }
        return count
    }

    private var totalLinkCount: Int {
        parentTags.reduce(0) { $0 + $1.totalLinkCount }
    }

    // MARK: - Body

    var body: some View {
        List {
            exportSection
            importSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.large)
        // Export share sheet
        .sheet(isPresented: $showShareSheet) {
            if let url = exportFileURL {
                ActivitySheet(items: [url])
                    .ignoresSafeArea()
            }
        }
        // Import file picker
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.html, UTType(filenameExtension: "html") ?? .html],
            allowsMultipleSelection: false
        ) { result in
            handlePickedFile(result)
        }
        // Import preview / confirmation
        .sheet(isPresented: $showImportPreview) {
            ImportPreviewSheet(tags: importPreview) { confirmed in
                showImportPreview = false
                if confirmed { performImport(importPreview) }
            }
        }
        // Import parse error
        .alert("Import Failed", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage ?? "The file could not be read.")
        }
    }

    // MARK: - Export Section

    @ViewBuilder
    private var exportSection: some View {
        // Header + select-all
        Section {
            selectAllRow
        } header: {
            Text("Export")
        } footer: {
            Text("Exports as an HTML Bookmarks file (.html) — importable into Chrome, Safari, Firefox, Edge, or back into MarkIT. Progress notes are preserved.")
        }

        // Per-tag checkboxes
        if !parentTags.isEmpty {
            Section {
                ForEach(parentTags) { parent in
                    parentExportRow(parent)
                    if selectedTagIDs.contains(parent.id) || parent.childrenList.contains(where: { selectedTagIDs.contains($0.id) }) {
                        ForEach(parent.childrenList.sorted(by: { $0.createdAt < $1.createdAt })) { child in
                            childExportRow(child)
                        }
                    }
                }
            }
        }

        // Export action button
        Section {
            Button { generateAndShare() } label: {
                HStack {
                    Spacer()
                    Label(
                        selectedLinkCount == 0
                            ? "Select Tags to Export"
                            : "Export \(selectedLinkCount) \(selectedLinkCount == 1 ? "Link" : "Links")",
                        systemImage: "square.and.arrow.up"
                    )
                    .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            .disabled(selectedLinkCount == 0)
        }
    }

    // MARK: - Select All Row

    private var selectAllRow: some View {
        Button {
            withAnimation {
                if isAllSelected {
                    selectedTagIDs.removeAll()
                } else {
                    selectedTagIDs = allTagIDs
                }
            }
        } label: {
            HStack(spacing: 14) {
                selectionCircle(filled: isAllSelected, partial: !selectedTagIDs.isEmpty && !isAllSelected)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isAllSelected ? "Deselect All" : "Select All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("\(parentTags.count) tag\(parentTags.count == 1 ? "" : "s") · \(totalLinkCount) link\(totalLinkCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Parent Export Row

    private func parentExportRow(_ tag: Tag) -> some View {
        let selected = selectedTagIDs.contains(tag.id)
        return Button {
            withAnimation {
                toggleParent(tag)
            }
        } label: {
            HStack(spacing: 14) {
                selectionCircle(filled: selected, partial: false)

                ZStack {
                    Circle()
                        .fill(Color(hex: tag.colorHex))
                        .frame(width: 34, height: 34)
                    Text(tag.emoji)
                        .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(subtitleFor(tag))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Chevron indicates children can be shown
                if !tag.childrenList.isEmpty {
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Child Export Row

    private func childExportRow(_ tag: Tag) -> some View {
        let selected = selectedTagIDs.contains(tag.id)
        return Button {
            withAnimation {
                if selected { selectedTagIDs.remove(tag.id) } else { selectedTagIDs.insert(tag.id) }
            }
        } label: {
            HStack(spacing: 14) {
                // Indent
                Color.clear.frame(width: 20)

                selectionCircle(filled: selected, partial: false)

                ZStack {
                    Circle()
                        .fill(Color(hex: tag.colorHex))
                        .frame(width: 28, height: 28)
                    Text(tag.emoji)
                        .font(.caption)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text("\(tag.linksList.count) link\(tag.linksList.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Import Section

    @ViewBuilder
    private var importSection: some View {
        Section {
            Button {
                showImportPicker = true
            } label: {
                HStack {
                    Spacer()
                    Label("Import Bookmarks", systemImage: "square.and.arrow.down")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Import")
        } footer: {
            Text("Import an .html bookmarks file exported from MarkIT or any browser. Tags, subtags, and reading progress are restored automatically.")
        }
    }

    // MARK: - Selection Helpers

    /// Tapping a parent toggles it; its children become visible but keep their own state.
    private func toggleParent(_ tag: Tag) {
        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.remove(tag.id)
            // Also deselect children so the section collapses cleanly
            for child in tag.childrenList { selectedTagIDs.remove(child.id) }
        } else {
            selectedTagIDs.insert(tag.id)
            // Auto-select children too for convenience (user can deselect individually)
            for child in tag.childrenList { selectedTagIDs.insert(child.id) }
        }
    }

    private func subtitleFor(_ tag: Tag) -> String {
        var parts: [String] = []
        if !tag.linksList.isEmpty {
            parts.append("\(tag.linksList.count) link\(tag.linksList.count == 1 ? "" : "s")")
        }
        if !tag.childrenList.isEmpty {
            parts.append("\(tag.childrenList.count) subtag\(tag.childrenList.count == 1 ? "" : "s")")
        }
        return parts.isEmpty ? "Empty" : parts.joined(separator: " · ")
    }

    // MARK: - Selection Circle

    @ViewBuilder
    private func selectionCircle(filled: Bool, partial: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(filled || partial ? Color.accentColor : Color(.systemGray4), lineWidth: 1.5)
                .frame(width: 22, height: 22)

            if filled {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            } else if partial {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 22, height: 22)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.accentColor)
                    .frame(width: 10, height: 2)
            }
        }
    }

    // MARK: - Export Action

    private func generateAndShare() {
        let html = BookmarkExporter.exportHTML(selectedTagIDs: selectedTagIDs, parentTags: parentTags)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "MarkIT-\(formatter.string(from: Date())).html"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
            exportFileURL = url
            showShareSheet = true
        } catch {
            importErrorMessage = "Could not create export file: \(error.localizedDescription)"
            showImportError = true
        }
    }

    // MARK: - Import Action

    private func handlePickedFile(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showImportError = true

        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            do {
                let html = try String(contentsOf: url, encoding: .utf8)
                let parsed = BookmarkExporter.parseHTML(html)
                guard !parsed.isEmpty else {
                    importErrorMessage = "No bookmarks were found in this file."
                    showImportError = true
                    return
                }
                importPreview = parsed
                showImportPreview = true
            } catch {
                importErrorMessage = "Could not read the file: \(error.localizedDescription)"
                showImportError = true
            }
        }
    }

    private func performImport(_ tags: [BookmarkExporter.ImportedTag]) {
        for imported in tags {
            let tag = Tag(name: imported.name, emoji: imported.emoji, colorHex: imported.colorHex)
            modelContext.insert(tag)

            for il in imported.links {
                let link = SavedLink(url: il.url, title: il.title, tag: tag)
                link.savedAt = il.savedAt
                link.progressPercent = il.progressPercent
                link.progressURL = il.progressURL
                link.progressNote = il.progressNote
                if il.progressPercent > 0 { link.lastProgressAt = Date() }
                modelContext.insert(link)
            }

            for importedChild in imported.children {
                let child = Tag(name: importedChild.name, emoji: importedChild.emoji, colorHex: importedChild.colorHex, parent: tag)
                modelContext.insert(child)

                for il in importedChild.links {
                    let link = SavedLink(url: il.url, title: il.title, tag: child)
                    link.savedAt = il.savedAt
                    link.progressPercent = il.progressPercent
                    link.progressURL = il.progressURL
                    link.progressNote = il.progressNote
                    if il.progressPercent > 0 { link.lastProgressAt = Date() }
                    modelContext.insert(link)
                }
            }
        }
    }
}

// MARK: - Import Preview Sheet

private struct ImportPreviewSheet: View {
    let tags: [BookmarkExporter.ImportedTag]
    let onDismiss: (Bool) -> Void

    private var totalLinks: Int { tags.reduce(0) { $0 + $1.totalLinkCount } }
    private var totalWithProgress: Int {
        func count(_ tag: BookmarkExporter.ImportedTag) -> Int {
            tag.links.filter { $0.progressPercent > 0 }.count +
            tag.children.reduce(0) { $0 + count($1) }
        }
        return tags.reduce(0) { $0 + count($1) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Summary header
                Section {
                    HStack(spacing: 16) {
                        summaryPill(value: "\(tags.count)", label: "Tags")
                        Divider().frame(height: 32)
                        summaryPill(value: "\(totalLinks)", label: "Links")
                        if totalWithProgress > 0 {
                            Divider().frame(height: 32)
                            summaryPill(value: "\(totalWithProgress)", label: "With Progress")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                // Tag tree preview
                Section("Will be imported") {
                    ForEach(tags) { tag in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 10) {
                                Text(tag.emoji)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(tag.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(previewSubtitle(tag))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            // Subtags
                            if !tag.children.isEmpty {
                                ForEach(tag.children) { child in
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.turn.down.right")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                        Text(child.emoji)
                                        Text(child.name)
                                            .font(.subheadline)
                                        Text("(\(child.links.count) links)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss(false) }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") { onDismiss(true) }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func previewSubtitle(_ tag: BookmarkExporter.ImportedTag) -> String {
        var parts: [String] = []
        if !tag.links.isEmpty { parts.append("\(tag.links.count) link\(tag.links.count == 1 ? "" : "s")") }
        if !tag.children.isEmpty { parts.append("\(tag.children.count) subtag\(tag.children.count == 1 ? "" : "s")") }
        return parts.joined(separator: " · ")
    }

    private func summaryPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Activity Sheet (UIActivityViewController wrapper)

struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
