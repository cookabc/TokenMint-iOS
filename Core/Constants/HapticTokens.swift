import SwiftUI

/// Maps app-level haptic intents to SwiftUI `SensoryFeedback`.
enum HapticToken {
    /// Button tap → light impact
    case buttonTap
    /// Selection / toggle → selection feedback
    case selection
    /// Copy TOTP code → success
    case success
    /// Delete confirmation → warning
    case warning
    /// Error → error
    case error
    /// Long-press trigger → medium impact
    case longPress

    var feedback: SensoryFeedback {
        switch self {
        case .buttonTap: .impact(weight: .light)
        case .selection: .selection
        case .success:   .success
        case .warning:   .warning
        case .error:     .error
        case .longPress: .impact(weight: .medium)
        }
    }
}
