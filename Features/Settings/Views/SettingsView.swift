import SwiftUI

struct SettingsView: View {
    @Environment(BiometricService.self) private var biometricService
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("selectedTheme") private var selectedTheme: AppThemeOption = .system

    var body: some View {
        @Bindable var biometricService = biometricService

        Form {
            if biometricService.biometryType != .none {
                Section("Security") {
                    Toggle(biometricLabel, isOn: $biometricService.isEnabled)
                        .accessibilityIdentifier(AccessibilityID.biometricToggle)
                }
            }

            Section("Preferences") {
                Toggle("Haptic Feedback", isOn: $hapticEnabled)
                    .accessibilityIdentifier(AccessibilityID.hapticToggle)

                Picker("Theme", selection: $selectedTheme) {
                    ForEach(AppThemeOption.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .accessibilityIdentifier(AccessibilityID.settingsThemePicker)
            }

            Section("About") {
                LabeledContent("Version") {
                    Text(
                        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                            ?? "1.0"
                    )
                }
            }
        }
        .navigationTitle("Settings")
    }

    private var biometricLabel: String {
        switch biometricService.biometryType {
        case .faceID: String(localized: "Face ID")
        case .touchID: String(localized: "Touch ID")
        case .opticID: String(localized: "Optic ID")
        default: String(localized: "Biometric Unlock")
        }
    }
}
