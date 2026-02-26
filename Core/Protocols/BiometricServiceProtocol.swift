import LocalAuthentication

/// Abstraction for biometric authentication.
@MainActor
protocol BiometricServiceProtocol: Observable {
    var isLocked: Bool { get }
    var biometryType: LABiometryType { get }
    var isEnabled: Bool { get set }
    func checkAvailability()
    func authenticate() async throws
    func lockIfNeeded()
}
