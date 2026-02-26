import SwiftUI

extension View {
    /// Applies a press-down scale effect.
    func pressEffect() -> some View {
        self.buttonStyle(PressEffectButtonStyle())
    }
}

struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AnimationTokens.quick, value: configuration.isPressed)
    }
}
