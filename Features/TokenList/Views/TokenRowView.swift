import SwiftUI

/// A single token row showing issuer, account, TOTP code with countdown ring,
/// copy-on-tap, and pin indicator.
struct TokenRowView: View {
    let token: Token
    let totpService: TOTPService

    @State private var code: String = ""
    @State private var remaining: Int = 30
    @State private var progress: Double = 0
    @State private var copied = false
    @State private var bouncing = false

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            // Left: issuer icon + labels
            issuerSection

            Spacer()

            // Right: TOTP code + countdown ring
            codeSection
        }
        .padding(.vertical, DesignTokens.Spacing.small)
        .contentShape(Rectangle())
        .onTapGesture { copyCode() }
        .task { startTimer() }
        .accessibilityIdentifier(AccessibilityID.tokenRow)
        .accessibilityLabel(AccessibilityLabel.copyToken(token.issuer))
        .accessibilityHint(AccessibilityHint.tokenRow)
    }

    // MARK: - Issuer Section

    private var issuerSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
            HStack(spacing: DesignTokens.Spacing.extraSmall) {
                if token.isPinned {
                    Image(systemName: "pin.fill")
                        .font(DesignTokens.Size.pinIcon)
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
                Text(token.issuer)
                    .font(DesignTokens.Typography.headline)
                    .lineLimit(1)
            }
            if !token.account.isEmpty {
                Text(token.account)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Code Section

    private var codeSection: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            // TOTP code
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedCode)
                    .font(DesignTokens.Typography.code)
                    .contentTransition(.numericText())
                    .foregroundStyle(DesignTokens.Colors.primary)
                    .accessibilityIdentifier(AccessibilityID.totpCode)

                if copied {
                    Text("Copied!")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.success)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Countdown ring
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.tertiary.opacity(0.3), lineWidth: DesignTokens.Size.ringStroke)
                Circle()
                    .trim(from: 0, to: 1 - progress)
                    .stroke(
                        remaining <= 5 ? DesignTokens.Colors.countdownUrgent : DesignTokens.Colors.countdown,
                        style: StrokeStyle(lineWidth: DesignTokens.Size.ringStroke, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text("\(remaining)")
                    .font(DesignTokens.Typography.caption)
                    .contentTransition(.numericText())
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            .frame(width: DesignTokens.Size.countdownRing, height: DesignTokens.Size.countdownRing)
            .accessibilityIdentifier(AccessibilityID.countdownRing)
            .symbolEffect(.bounce, value: bouncing)
        }
    }

    private var formattedCode: String {
        guard code.count >= 6 else { return code }
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return "\(code[..<mid]) \(code[mid...])"
    }

    // MARK: - Timer

    private func startTimer() {
        updateCode()
        // Use structured concurrency instead of Timer.scheduledTimer
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                let oldRemaining = remaining
                updateCode()
                if remaining > oldRemaining {
                    bouncing.toggle()
                }
            }
        }
    }

    private func updateCode() {
        withAnimation(AnimationTokens.quick) {
            code = totpService.generateCode(for: token)
            remaining = totpService.remainingSeconds(period: token.period)
            progress = totpService.progress(period: token.period)
        }
    }

    // MARK: - Copy

    private func copyCode() {
        UIPasteboard.general.string = code
        withAnimation(AnimationTokens.spring) {
            copied = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(AnimationTokens.quick) {
                copied = false
            }
        }
    }
}
