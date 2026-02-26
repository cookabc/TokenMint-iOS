import SwiftUI

struct LockScreenView: View {
    @Environment(BiometricService.self) private var biometricService

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            Image(systemName: biometricIcon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
                .symbolEffect(.bounce, options: .repeating.speed(0.5))

            Text("TokenMint")
                .font(DesignTokens.Typography.largeTitle)

            Text("Tap to Unlock")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(.secondary)

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
