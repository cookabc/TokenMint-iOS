//
//  TokenRowView.swift
//  TokenMint
//
//  List row displaying a TOTP token
//

import SwiftUI

struct TokenRowView: View {
    let token: Token
    @State private var isCopied: Bool = false
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            let code = TOTPService.shared.generateCode(for: token) ?? "000000"
            let progress = TOTPService.shared.progress(for: token.period)
            let isExpiring = progress < 0.16
            
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
                    Text(formatCode(code))
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(isExpiring ? .red : .primary)
                        .onTapGesture {
                            copyToClipboard(code: code)
                        }

                    CircularProgressView(progress: progress, color: isExpiring ? .red : .blue)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.vertical, 8)
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
    
    private func formatCode(_ code: String) -> String {
        // Add space in middle for 6 digits (e.g. 123 456)
        if code.count == 6 {
            let first = code.prefix(3)
            let last = code.suffix(3)
            return "\(first) \(last)"
        }
        return code
    }
    
    private func copyToClipboard(code: String) {
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
