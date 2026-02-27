import SwiftUI

struct LockScreenView: View {
    @Environment(BiometricService.self) private var biometricService

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.large) {
            Spacer()

            Image(systemName: biometricIcon)
                .font(.system(size: DesignTokens.Size.lockIcon))
                .foregroundStyle(DesignTokens.Colors.secondary)
                .symbolEffect(.bounce, options: .repeating.speed(0.5))

            Text("TokenMint")
                .font(DesignTokens.Typography.largeTitle)

            Text("Tap to Unlock")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .onTapGesture {
            Task {
                try? await biometricService.authenticate()
            }
        }
        .accessibilityLabel(AccessibilityLabel.unlock)
        .accessibilityHint(AccessibilityHint.unlock)
        .accessibilityIdentifier(AccessibilityID.unlockButton)
        .task {
            try? await biometricService.authenticate()
        }
    }

    private var biometricIcon: String {
        switch biometricService.biometryType {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        default: "lock.fill"
        }
    }
}
