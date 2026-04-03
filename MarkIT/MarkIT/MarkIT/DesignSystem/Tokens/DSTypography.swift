import SwiftUI

// MARK: - DSFont

/// Canonical font tokens with weights baked in.
/// Use these instead of ad-hoc `.font(.headline)` calls so the whole app
/// can be restyled from one place.
enum DSFont {
    static var largeTitle:  Font { .system(.largeTitle,  design: .default, weight: .bold) }
    static var title:       Font { .system(.title,       design: .default, weight: .semibold) }
    static var title2:      Font { .system(.title2,      design: .default, weight: .semibold) }
    static var headline:    Font { .system(.headline,    design: .default, weight: .semibold) }
    static var body:        Font { .system(.body,        design: .default, weight: .regular) }
    static var subheadline: Font { .system(.subheadline, design: .default, weight: .medium) }
    static var caption:     Font { .system(.caption,     design: .default, weight: .regular) }
    static var caption2:    Font { .system(.caption2,    design: .default, weight: .regular) }
}
