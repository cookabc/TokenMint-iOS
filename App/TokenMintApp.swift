import SwiftUI

@main
struct TokenMintApp: App {
    @State private var vaultService: VaultService
    @State private var biometricService = BiometricService()
    @State private var router = Router()
    @AppStorage("selectedTheme") private var selectedTheme: AppThemeOption = .system
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let keychain = KeychainService()
        let repository = VaultRepository(keychain: keychain)
        self._vaultService = State(
            initialValue: VaultService(
                repository: repository,
                keychain: keychain
            ))
    }

    var body: some Scene {
        WindowGroup {
            if biometricService.isLocked {
                LockScreenView()
                    .environment(biometricService)
                    .preferredColorScheme(selectedTheme.colorScheme)
                    .localeOverride(appLanguage)
                    .id(appLanguage)
            } else {
                TokenListView()
                    .environment(vaultService)
                    .environment(biometricService)
                    .environment(router)
                    .preferredColorScheme(selectedTheme.colorScheme)
                    .localeOverride(appLanguage)
                    .id(appLanguage)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                biometricService.lockIfNeeded()
                UIPasteboard.general.items = []
            case .active:
                biometricService.checkAvailability()
            default:
                break
            }
        }
    }
}
