import UIKit

/// Centralized haptic feedback service.
@MainActor
final class HapticService: HapticServiceProtocol {
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    func play(_ token: HapticTokens) {
        switch token {
        case .buttonTap:
            impactLight.impactOccurred()
        case .selection:
            selectionGenerator.selectionChanged()
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .longPress:
            impactMedium.impactOccurred()
        }
    }
}
