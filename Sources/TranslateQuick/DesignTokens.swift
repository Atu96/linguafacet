import CoreGraphics

enum TQLayout {
    static let micro: CGFloat = 4
    static let compact: CGFloat = 8
    static let dense: CGFloat = 12
    static let standard: CGFloat = 16
    static let section: CGFloat = 24

    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 12
    static let cardRadius: CGFloat = 18

    static let controlTarget: CGFloat = 28
    static let tabHeight: CGFloat = 34
    static let compactBreakpoint: CGFloat = 780

    // Keep both translation workspaces readable when the window is resized.
    static let mainWindowMinWidth: CGFloat = 820
    static let mainWindowMinHeight: CGFloat = 560
    static let mainWindowScreenMargin: CGFloat = 12
    static let mainWindowFallbackMaxHeight: CGFloat = 900
}
