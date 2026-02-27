import SwiftUI

enum DesignTokens {
    // MARK: - Colors

    enum Colors {
        static let primary = Color(.label)
        static let secondary = Color(.secondaryLabel)
        static let tertiary = Color(.tertiaryLabel)
        static let surface = Color(.secondarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        static let accent = Color(hex: "6C63FF")
        static let error = Color(.systemRed)
        static let success = Color(.systemGreen)
        static let warning = Color(.systemOrange)
        static let countdown = Color(hex: "4CAF50")
        static let countdownUrgent = Color(.systemRed)
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle: Font = .title.weight(.medium)
        static let title: Font = .title3.weight(.bold)
        static let headline: Font = .headline
        static let body: Font = .body
        static let code = Font.system(size: 32, weight: .bold, design: .monospaced)
        static let codeSmall = Font.system(size: 24, weight: .semibold, design: .monospaced)
        static let caption: Font = .caption.weight(.medium)
        static let successIcon: Font = .title2
        static let pinIcon: Font = .caption2
    }

    // MARK: - Spacing

    enum Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    // MARK: - Radius

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
    }

    // MARK: - Sizes

    enum Size {
        static let countdownRing: CGFloat = 32
        static let lockIcon: CGFloat = 64
        static let ringStroke: CGFloat = 3
    }
}
