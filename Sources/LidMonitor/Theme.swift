import SwiftUI

/// Design tokens shared across the popover so colors stay in lock-step with the app icon.
enum Theme {
    static let primary = LinearGradient(
        colors: [
            Color(red: 0.30, green: 0.85, blue: 1.00),
            Color(red: 0.55, green: 0.45, blue: 1.00),
            Color(red: 0.95, green: 0.40, blue: 0.75),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryHorizontal = LinearGradient(
        colors: [
            Color(red: 0.30, green: 0.85, blue: 1.00),
            Color(red: 0.55, green: 0.45, blue: 1.00),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let dimAccent = LinearGradient(
        colors: [.orange.opacity(0.55), .pink.opacity(0.45)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let glassBorder = LinearGradient(
        colors: [.white.opacity(0.35), .white.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
