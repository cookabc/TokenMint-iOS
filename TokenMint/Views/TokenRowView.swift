//
//  TokenRowView.swift
//  TokenMint
//
//  List row displaying a TOTP token
//

import SwiftUI
import Combine

struct TokenRowView: View {
    let token: Token
    @State private var code: String = "000000"
    @State private var progress: Double = 1.0
    @State private var isCopied: Bool = false
    
    // Timer to update code and progress
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Token Info
            VStack(alignment: .leading, spacing: 4) {
                Text(token.issuer.isEmpty ? "Unknown" : token.issuer)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(token.account.isEmpty ? token.displayName : token.account)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Right: Code and Timer
            HStack(spacing: 12) {
                Text(formattedCode)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(isExpiring ? .red : .primary)
                    .onTapGesture {
                        copyToClipboard()
                    }
                
                CircularProgressView(progress: progress, color: isExpiring ? .red : .blue)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.vertical, 8)
        .onReceive(timer) { _ in
            updateCode()
        }
        .onAppear {
            updateCode()
        }
        .overlay(
            Group {
                if isCopied {
                    Text(L10n.copied)
                        .font(.caption)
                        .padding(6)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
    }
    
    private var formattedCode: String {
        // Add space in middle for 6 digits (e.g. 123 456)
        if code.count == 6 {
            let first = code.prefix(3)
            let last = code.suffix(3)
            return "\(first) \(last)"
        }
        return code
    }
    
    private var isExpiring: Bool {
        progress < 0.16 // Less than 5 seconds (approx 1/6 of 30s)
    }
    
    private func updateCode() {
        // Generate new code
        if let newCode = TOTPService.shared.generateCode(for: token) {
            self.code = newCode
        }
        
        // Update progress
        self.progress = TOTPService.shared.progress(for: token.period)
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = code
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show copied toast
        withAnimation {
            isCopied = true
        }
        
        // Hide toast after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isCopied = false
            }
        }
    }
}
