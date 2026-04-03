import SwiftUI

// MARK: - DSColors

/// Semantic colour tokens — prefer these over raw system colours in views.
enum DSColors {
    // Backgrounds
    static var background: Color { Color(.systemBackground) }
    static var secondaryBackground: Color { Color(.secondarySystemBackground) }
    static var tertiaryBackground: Color { Color(.tertiarySystemBackground) }
    static var surface: Color { Color(.systemBackground) }
    static var surfaceElevated: Color { Color(.secondarySystemBackground) }

    // Text
    static var primary: Color { Color(.label) }
    static var secondary: Color { Color(.secondaryLabel) }
    static var tertiary: Color { Color(.tertiaryLabel) }

    // Interactive
    static var accent: Color { Color.accentColor }
    static var destructive: Color { Color(.systemRed) }

    // Separators
    static var separator: Color { Color(.separator) }
}

// MARK: - DSTagColor

/// Resolves a tag's hex colour into adaptive background and foreground colours
/// that look great in both light and dark mode.
struct DSTagColor {
    let background: Color
    let foreground: Color
    /// A semi-transparent tinted version for use in list row accents etc.
    let tint: Color

    init(hex: String, colorScheme: ColorScheme) {
        let base = Color(hex: hex)
        let luminance = DSTagColor.relativeLuminance(hex: hex)

        if colorScheme == .dark {
            // Slightly dim and desaturate in dark mode to avoid eye-searing brightness
            background = base.opacity(0.82)
        } else {
            background = base
        }

        // Accessible foreground: dark text on bright cards, white text on dark cards
        foreground = luminance > 0.35 ? Color.black.opacity(0.85) : Color.white
        tint = base.opacity(0.18)
    }

    // MARK: Luminance

    /// Relative luminance per WCAG 2.1 (0 = black, 1 = white)
    static func relativeLuminance(hex: String) -> Double {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6 else { return 0.5 }
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        // Linearise
        func lin(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    }
}
