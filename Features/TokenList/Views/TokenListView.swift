import SwiftUI

struct TokenListView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(Router.self) private var router

    @State private var searchText = ""
    @State private var editMode: EditMode = .inactive

    private let totpService = TOTPService()

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
                    tokenList
                }
            }
            .navigationTitle("TokenMint")
            .searchable(text: $searchText, prompt: "Search tokens")
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
                    .accessibilityIdentifier("settings_button")
                    .accessibilityLabel(AccessibilityLabel.settings)
                    .accessibilityHint(AccessibilityHint.settings)
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .accessibilityLabel(AccessibilityLabel.editList)
                        .accessibilityIdentifier(AccessibilityID.editButton)
                }
            }
            .environment(\.editMode, $editMode)
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .addToken:
                    AddTokenView()
                case .scanner:
                    ScannerView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .task {
            try? await vaultService.loadVault()
        }
    }

    // MARK: - Token List

    private var tokenList: some View {
        List {
            ForEach(filteredTokens, id: \.id) { token in
                TokenRowView(token: token, totpService: totpService)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task { try? await vaultService.deleteToken(token) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .accessibilityLabel(AccessibilityLabel.deleteToken)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            Task { await togglePin(token) }
                        } label: {
                            Label(
                                token.isPinned
                                    ? String(localized: "Unpin")
                                    : String(localized: "Pin"),
                                systemImage: token.isPinned ? "pin.slash" : "pin"
                            )
                        }
                        .tint(DesignTokens.Colors.accent)
                        .accessibilityLabel(AccessibilityLabel.pinToken(token.isPinned))
                    }
                    .listRowBackground(Color.clear)
            }
            .onMove(perform: moveTokens)
        }
        .listStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.tokenList)
    }

    // MARK: - Data

    private var filteredTokens: [Token] {
        let sorted = vaultService.vault.tokens.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.sortOrder < rhs.sortOrder
        }
        guard !searchText.isEmpty else { return sorted }
        let query = searchText.lowercased()
        return sorted.filter {
            $0.issuer.lowercased().contains(query) || $0.account.lowercased().contains(query)
        }
    }

    private func moveTokens(from source: IndexSet, to destination: Int) {
        var tokens = filteredTokens
        tokens.move(fromOffsets: source, toOffset: destination)
        Task { try? await vaultService.reorderTokens(tokens) }
    }

    private func togglePin(_ token: Token) async {
        var updated = token
        updated.isPinned.toggle()
        updated.updatedAt = Date()
        try? await vaultService.updateToken(updated)
    }
}

#Preview {
    let keychain = KeychainService()
    let repo = VaultRepository(keychain: keychain)
    TokenListView()
        .environment(VaultService(repository: repo, keychain: keychain))
        .environment(Router())
}
