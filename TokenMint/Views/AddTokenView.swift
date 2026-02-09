//
//  AddTokenView.swift
//  TokenMint
//
//  View for manually adding a new TOTP token
//

import SwiftUI

struct AddTokenView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var vaultService: VaultService
    
    @State private var issuer: String = ""
    @State private var account: String = ""
    @State private var secret: String = ""
    @State private var algorithm: TOTPAlgorithm = .sha1
    @State private var digits: Int = 6
    @State private var period: Int = 30
    
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(L10n.account)) {
                    TextField(L10n.servicePlaceholder, text: $issuer)
                    TextField(L10n.accountPlaceholder, text: $account)
                }
                
                Section(header: Text("Secret Key")) {
                    TextField("Base32 Key", text: $secret)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section(header: Text(L10n.algorithm)) {
                    Picker(L10n.algorithm, selection: $algorithm) {
                        ForEach(TOTPAlgorithm.allCases, id: \.self) { algo in
                            Text(algo.rawValue).tag(algo)
                        }
                    }
                    
                    Picker(L10n.digits, selection: $digits) {
                        Text("6").tag(6)
                        Text("8").tag(8)
                    }
                    
                    Picker(L10n.period, selection: $period) {
                        Text("30s").tag(30)
                        Text("60s").tag(60)
                    }
                }
            }
            .navigationTitle(L10n.addAccount)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) {
                        saveToken()
                    }
                    .disabled(secret.isEmpty)
                }
            }
        }
    }
    
    private func saveToken() {
        // Validate Secret
        guard TOTPService.shared.isValidBase32(secret) else {
            errorMessage = L10n.invalidFormat
            return
        }
        
        // Create Token
        let token = Token(
            issuer: issuer,
            account: account,
            secret: secret,
            digits: digits,
            period: period,
            algorithm: algorithm
        )
        
        // Save to Vault
        do {
            try vaultService.addToken(token)
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
