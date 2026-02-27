import SwiftUI

/// View modifier that fires `SensoryFeedback` when a trigger value changes,
/// respecting the user's haptic-enabled preference.
struct HapticFeedbackModifier: ViewModifier {
    let token: HapticToken
    let trigger: Int
    @AppStorage("hapticEnabled") private var hapticEnabled = true

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(token.feedback, trigger: trigger) { _, _ in
                hapticEnabled
            }
    }
}

extension View {
    /// Attach a haptic feedback that fires whenever `trigger` changes.
    func hapticFeedback(_ token: HapticToken, trigger: some Equatable) -> some View {
        self.sensoryFeedback(token.feedback, trigger: trigger)
    }
}
