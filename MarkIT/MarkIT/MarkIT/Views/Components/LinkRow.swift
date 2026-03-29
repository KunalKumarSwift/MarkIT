import SwiftUI

struct LinkRow: View {
    let link: SavedLink

    private var faviconURL: URL? {
        guard let domain = URL(string: link.url)?.host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64")
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: link.savedAt, relativeTo: Date())
    }

    private var progressColor: Color {
        switch link.progressPercent {
        case 0: return .secondary
        case 1..<50: return .orange
        case 50..<100: return .blue
        default: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                AsyncImage(url: faviconURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                }
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                VStack(alignment: .leading, spacing: 2) {
                    Text(link.title.isEmpty ? link.url : link.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(link.domain)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Show "continue" badge when there's saved progress
                if link.progressPercent > 0 && link.progressPercent < 100 {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(progressColor)
                        .font(.subheadline)
                } else if link.progressPercent == 100 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(progressColor)
                        .font(.subheadline)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Progress bar + metadata — only shown once progress has been set
            if link.hasProgress {
                progressSection
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: Double(link.progressPercent), total: 100)
                .tint(progressColor)

            HStack(spacing: 4) {
                Text(link.progressPercent == 100 ? "Complete" : "\(link.progressPercent)% complete")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(progressColor)

                if let note = link.progressNote, !note.isEmpty {
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if let lastDate = link.lastProgressAt {
                    Text(RelativeDateTimeFormatter().localizedString(for: lastDate, relativeTo: Date()))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        // Indent to align with the title text (past the favicon)
        .padding(.leading, 36)
    }
}
