/// Abstraction for haptic feedback.
@MainActor
protocol HapticServiceProtocol {
    func play(_ token: HapticTokens)
}
