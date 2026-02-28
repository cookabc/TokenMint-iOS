import LocalAuthentication
import SwiftUI

/// Manages Face ID / Touch ID with passcode fallback.
@MainActor
@Observable
final class BiometricService: BiometricServiceProtocol {
    private(set) var isLocked: Bool = false
    private(set) var biometryType: LABiometryType = .none
    @ObservationIgnored
    @AppStorage("biometricEnabled") var isEnabled: Bool = false

    func checkAvailability() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometryType = context.biometryType
        } else {
            biometryType = .none
        }
    }

    func authenticate() async throws {
        let context = LAContext()
        context.localizedFallbackTitle = L("Use Passcode")
        let reason = L("Unlock your vault")
        _ = try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        )
        isLocked = false
    }

    func lockIfNeeded() {
        if isEnabled { isLocked = true }
    }
}
