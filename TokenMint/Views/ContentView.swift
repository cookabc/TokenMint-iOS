//
//  ContentView.swift
//  TokenMint
//
//  Main view displaying the list of TOTP tokens
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vaultService: VaultService
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if vaultService.vault.tokens.isEmpty {
                    emptyStateView
                } else {
                    tokenList
                }
            }
            .navigationTitle("TokenMint")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !vaultService.vault.tokens.isEmpty {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTokenView()
            }
            .searchable(text: $searchText, prompt: L10n.searchAccounts)
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(L10n.noAccounts)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(L10n.addFirstAccount)
                .foregroundColor(.secondary)
            
            Button(action: { showingAddSheet = true }) {
                Text(L10n.addAccount)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
    }
    
    private var tokenList: some View {
        List {
            ForEach(filteredTokens) { token in
                TokenRowView(token: token)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteToken(token)
                        } label: {
                            Label(L10n.delete, systemImage: "trash")
                        }
                    }
            }
            .onMove(perform: moveTokens)
            .onDelete(perform: deleteTokens)
        }
    }
    
    // MARK: - Helpers
    
    private var filteredTokens: [Token] {
        if searchText.isEmpty {
            return vaultService.vault.tokens
        } else {
            return vaultService.vault.tokens.filter { token in
                token.issuer.localizedCaseInsensitiveContains(searchText) ||
                token.account.localizedCaseInsensitiveContains(searchText) ||
                token.label.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func deleteToken(_ token: Token) {
        try? vaultService.deleteToken(id: token.id)
    }
    
    private func deleteTokens(at offsets: IndexSet) {
        // Find tokens to delete based on the filtered list is tricky with IndexSet if searching
        // Ideally we should disable deletion while searching or handle it carefully.
        // For simplicity, if searching, we might not support bulk delete or we map back.
        
        if !searchText.isEmpty {
            // If searching, IndexSet refers to filteredTokens
            let tokensToDelete = offsets.map { filteredTokens[$0] }
            for token in tokensToDelete {
                try? vaultService.deleteToken(id: token.id)
            }
        } else {
            // Direct mapping
            // But VaultService expects ID or we can iterate.
            // VaultService has deleteToken(id:).
            // Let's rely on offsets if we are not searching.
            // Actually VaultService doesn't have delete(offsets:).
            
            let tokensToDelete = offsets.map { vaultService.vault.tokens[$0] }
            for token in tokensToDelete {
                try? vaultService.deleteToken(id: token.id)
            }
        }
    }
    
    private func moveTokens(from source: IndexSet, to destination: Int) {
        // Only allow moving when not searching
        guard searchText.isEmpty else { return }
        
        try? vaultService.reorderTokens(from: source, to: destination)
    }
}
