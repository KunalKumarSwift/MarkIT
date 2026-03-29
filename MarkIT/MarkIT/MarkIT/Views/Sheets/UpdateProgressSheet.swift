import SwiftUI

struct UpdateProgressSheet: View {
    @Environment(\.dismiss) private var dismiss

    let link: SavedLink
    /// Pre-filled with the browser's current URL so the user doesn't have to type it.
    let currentBrowserURL: String

    @State private var progressPercent: Double
    @State private var progressURL: String
    @State private var progressNote: String

    init(link: SavedLink, currentBrowserURL: String) {
        self.link = link
        self.currentBrowserURL = currentBrowserURL
        _progressPercent = State(initialValue: Double(link.progressPercent))
        // Pre-fill with browser's current URL; fall back to saved progress URL or original.
        let urlToPreFill = !currentBrowserURL.isEmpty ? currentBrowserURL : (link.progressURL ?? link.url)
        _progressURL = State(initialValue: urlToPreFill)
        _progressNote = State(initialValue: link.progressNote ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Big percentage display + slider
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("\(Int(progressPercent))%")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(progressColor)
                                .contentTransition(.numericText())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(progressLabel)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(progressColor)

                                if let lastDate = link.lastProgressAt {
                                    Text("Updated \(RelativeDateTimeFormatter().localizedString(for: lastDate, relativeTo: Date()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.bottom, 8)
                        }

                        Slider(value: $progressPercent, in: 0...100, step: 5)
                            .tint(progressColor)
                            .animation(.easeOut(duration: 0.15), value: progressPercent)

                        HStack {
                            Text("Not started")
                            Spacer()
                            Text("Complete")
                        }
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // The URL where the user stopped — auto-filled from browser
                Section("Stopped at") {
                    TextField("https://docs.example.com/section", text: $progressURL, axis: .vertical)
                        .lineLimit(2...3)
                        .font(.footnote)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }

                // Free-text note
                Section("Note (optional)") {
                    TextField("e.g. Finished closures, starting on async/await", text: $progressNote, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Original URL for reference
                Section {
                    HStack {
                        Text("Original URL")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(link.url)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .navigationTitle("Update Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helpers

    private var progressColor: Color {
        switch Int(progressPercent) {
        case 0: return .secondary
        case 1..<50: return .orange
        case 50..<100: return .blue
        default: return .green
        }
    }

    private var progressLabel: String {
        switch Int(progressPercent) {
        case 0: return "Not started"
        case 100: return "Complete"
        default: return "In progress"
        }
    }

    // MARK: - Save

    private func save() {
        link.progressPercent = Int(progressPercent)
        let trimmedURL = progressURL.trimmingCharacters(in: .whitespaces)
        link.progressURL = trimmedURL.isEmpty ? nil : trimmedURL
        let trimmedNote = progressNote.trimmingCharacters(in: .whitespaces)
        link.progressNote = trimmedNote.isEmpty ? nil : trimmedNote
        link.lastProgressAt = Date()
        dismiss()
    }
}
