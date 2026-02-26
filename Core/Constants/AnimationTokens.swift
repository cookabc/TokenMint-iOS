import SwiftUI

enum AnimationTokens {
    /// Generic spring: buttons, selection, toggles
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)

    /// Quick feedback: tab switches, fast appearances
    static let quick = Animation.easeOut(duration: 0.2)

    /// Smooth transitions: page/content changes
    static let smooth = Animation.easeInOut(duration: 0.3)

    /// Countdown ring linear animation (TokenMint specific)
    static let countdown = Animation.linear(duration: 1.0)
}
