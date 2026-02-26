import SwiftUI

struct TokenListView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            Group {
                if vaultService.vault.tokens.isEmpty {
                    ContentUnavailableView(
                        "No Tokens Yet",
                        systemImage: "lock.shield",
                        description: Text("Add your first authenticator token")
                    )
                } else {
                    List(sortedTokens, id: \.id) { token in
                        Text("\(token.issuer) — \(token.account)")
                    }
                }
            }
            .navigationTitle("TokenMint")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            router.navigate(to: .addToken)
                        } label: {
                            Label("Add Manually", systemImage: "plus")
                        }
                        Button {
                            router.navigate(to: .scanner)
                        } label: {
                            Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(AccessibilityLabel.addToken)
                    .accessibilityHint(AccessibilityHint.addToken)
                    .accessibilityIdentifier(AccessibilityID.addTokenButton)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        router.navigate(to: .settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .addToken:
                    AddTokenView()
                case .scanner:
                    Text("QR Scanner — TODO W10")
                case .settings:
                    SettingsView()
                }
            }
        }
        .task {
            try? await vaultService.loadVault()
        }
    }

    private var sortedTokens: [Token] {
        vaultService.vault.tokens.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.sortOrder < rhs.sortOrder
        }
    }
}

#Preview {
    let keychain = KeychainService()
    let repo = VaultRepository(keychain: keychain)
    TokenListView()
        .environment(VaultService(repository: repo, keychain: keychain))
        .environment(Router())
}
