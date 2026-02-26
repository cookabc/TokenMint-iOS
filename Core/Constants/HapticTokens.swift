import UIKit

/// Centralized haptic feedback tokens.
enum HapticTokens {
    /// Button tap → light impact
    case buttonTap
    /// Selection / toggle → selection feedback
    case selection
    /// Copy TOTP code → notification success
    case success
    /// Delete confirmation → notification warning
    case warning
    /// Error → notification error
    case error
    /// Long-press trigger → medium impact
    case longPress
}
