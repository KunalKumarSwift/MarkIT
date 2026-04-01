import CoreGraphics

// MARK: - DSSpacing

enum DSSpacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 24
    static let xxl: CGFloat = 32
}

// MARK: - DSRadius

enum DSRadius {
    static let sm: CGFloat   = 8
    static let md: CGFloat   = 12
    static let lg: CGFloat   = 16
    static let xl: CGFloat   = 24
    static let full: CGFloat = 999
}

// MARK: - DSShadow

struct DSShadow {
    let color: Double   // opacity multiplier applied to shadow colour
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let card     = DSShadow(color: 0.12, radius: 6,  x: 0, y: 3)
    static let elevated = DSShadow(color: 0.18, radius: 16, x: 0, y: 8)
}
