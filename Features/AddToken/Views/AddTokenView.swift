import SwiftUI

struct AddTokenView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(Router.self) private var router

    @State private var issuer = ""
    @State private var account = ""
    @State private var secret = ""
    @State private var digits = 6
    @State private var period = 30
    @State private var algorithm: TOTPAlgorithm = .sha1

    private let totpService = TOTPService()

    var body: some View {
        Form {
            Section("Account Info") {
                TextField("Issuer (e.g. GitHub)", text: $issuer)
                    .accessibilityIdentifier(AccessibilityID.issuerField)
                TextField("Account (e.g. user@email.com)", text: $account)
                    .accessibilityIdentifier(AccessibilityID.accountField)
            }

            Section("Secret Key") {
                TextField("Base32 Secret", text: $secret)
                    .textInputAutocapitalization(.characters)
                    .accessibilityIdentifier(AccessibilityID.secretField)
            }

            Section("Advanced") {
                Picker("Digits", selection: $digits) {
                    Text("6").tag(6)
                    Text("8").tag(8)
                }
                Picker("Period", selection: $period) {
                    Text("30s").tag(30)
                    Text("60s").tag(60)
                }
                Picker("Algorithm", selection: $algorithm) {
                    ForEach(TOTPAlgorithm.allCases, id: \.self) { algo in
                        Text(algo.rawValue.uppercased()).tag(algo)
                    }
                }
            }
        }
        .navigationTitle("Add Token")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        let token = Token(
                            issuer: issuer,
                            account: account,
                            secret: secret,
                            digits: digits,
                            period: period,
                            algorithm: algorithm
                        )
                        try? await vaultService.addToken(token)
                        router.pop()
                    }
                }
                .disabled(!isValid)
                .accessibilityIdentifier(AccessibilityID.saveTokenButton)
            }
        }
    }

    private var isValid: Bool {
        !issuer.isEmpty && !secret.isEmpty && totpService.isValidBase32(secret)
    }
}
