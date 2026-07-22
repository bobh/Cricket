import SwiftUI

// Centralized design tokens for colors and fonts
enum DesignColor {
    // Brand palette
    static let brandBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let brandOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let brandGreen = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let brandPurple = Color(red: 0.6, green: 0.4, blue: 0.9)

    // Status colors
    static let statusOK = brandGreen
    static let statusWarning = brandOrange
    static let statusError = Color.red

    // Surfaces
    static let cardBackground = Color(.secondarySystemBackground)
}

enum DesignFont {
    static func readingLarge() -> Font { .system(.largeTitle, design: .rounded).weight(.bold) }
    static func readingXL() -> Font { .system(size: 48, weight: .bold, design: .rounded) }
    static func label() -> Font { .headline }
    static func caption() -> Font { .caption }
}
