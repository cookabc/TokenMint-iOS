import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(BiometricService.self) private var biometricService
    @Environment(VaultService.self) private var vaultService
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("selectedTheme") private var selectedTheme: AppThemeOption = .system
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system

    @State private var showImporter = false
    @State private var importResult: ImportResult?
    @State private var showImportAlert = false

    private enum ImportResult {
        case success(Int)
        case failure(String)
    }

    var body: some View {
        @Bindable var biometricService = biometricService

        Form {
            if biometricService.biometryType != .none {
                Section("Security") {
                    Toggle(biometricLabel, isOn: $biometricService.isEnabled)
                        .accessibilityLabel(AccessibilityLabel.biometricToggle)
                        .accessibilityIdentifier(AccessibilityID.biometricToggle)
                }
            }

            Section("Preferences") {
                Toggle("Haptic Feedback", isOn: $hapticEnabled)
                    .accessibilityLabel(AccessibilityLabel.hapticToggle)
                    .accessibilityIdentifier(AccessibilityID.hapticToggle)

                Picker("Theme", selection: $selectedTheme) {
                    ForEach(AppThemeOption.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .accessibilityLabel(AccessibilityLabel.themeSelector)
                .accessibilityIdentifier(AccessibilityID.settingsThemePicker)

                Picker("Language", selection: $appLanguage) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .accessibilityIdentifier("settings_language_picker")
            }

            Section("Data") {
                ShareLink(
                    item: exportJSON(),
                    preview: SharePreview("TokenMint Backup", image: Image(systemName: "lock.shield"))
                ) {
                    Label("Export Vault", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel(AccessibilityLabel.exportVault)
                .accessibilityHint(AccessibilityHint.exportVault)
                .accessibilityIdentifier(AccessibilityID.settingsExportButton)

                Button {
                    showImporter = true
                } label: {
                    Label("Import Vault", systemImage: "square.and.arrow.down")
                }
                .accessibilityLabel(AccessibilityLabel.importVault)
                .accessibilityHint(AccessibilityHint.importVault)
                .accessibilityIdentifier(AccessibilityID.settingsImportButton)
            }

            Section("About") {
                LabeledContent("Version") {
                    Text(
                        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                            ?? "1.0"
                    )
                }
                LabeledContent("Tokens") {
                    Text("\(vaultService.vault.tokens.count)")
                }
            }
        }
        .navigationTitle("Settings")
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            onCompletion: handleImport
        )
        .alert("Import Complete", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            switch importResult {
            case .success(let count):
                Text("\(count) token(s) imported successfully.")
            case .failure(let msg):
                Text("Import failed: \(msg)")
            case nil:
                Text("")
            }
        }
    }

    private var biometricLabel: String {
        switch biometricService.biometryType {
        case .faceID: L("Face ID")
        case .touchID: L("Touch ID")
        case .opticID: L("Optic ID")
        default: L("Biometric Unlock")
        }
    }

    // MARK: - Export / Import

    private func exportJSON() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let tokens = vaultService.vault.tokens
        guard let data = try? encoder.encode(tokens),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importResult = .failure(L("Access denied"))
                showImportAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let tokens = try decoder.decode([Token].self, from: data)
                let existingIds = Set(vaultService.vault.tokens.map(\.id))
                var imported = 0
                for token in tokens where !existingIds.contains(token.id) {
                    Task { try? await vaultService.addToken(token) }
                    imported += 1
                }
                importResult = .success(imported)
            } catch {
                importResult = .failure(error.localizedDescription)
            }
            showImportAlert = true

        case .failure(let error):
            importResult = .failure(error.localizedDescription)
            showImportAlert = true
        }
    }
}
