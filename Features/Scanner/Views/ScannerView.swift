import SwiftUI
import VisionKit

/// QR Code scanner using DataScannerViewController (iOS 16+).
struct ScannerView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(Router.self) private var router

    @State private var scannedToken: Token?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isScanning = true

    private let totpService = TOTPService()

    var body: some View {
        ZStack {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                DataScannerRepresentable(
                    onBarcodeFound: handleBarcode
                )
                .ignoresSafeArea()
            } else {
                ContentUnavailableView(
                    "Camera Not Available",
                    systemImage: "camera.off",
                    description: Text("This device does not support barcode scanning or camera access was denied.")
                )
            }

            // Overlay
            VStack {
                Spacer()
                if let token = scannedToken {
                    scannedTokenCard(token)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
        }
        .navigationTitle("Scan QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Scan Error", isPresented: $showError) {
            Button("OK") { isScanning = true }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Scanned Token Card

    private func scannedTokenCard(_ token: Token) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(token.issuer)
                        .font(DesignTokens.Typography.headline)
                    if !token.account.isEmpty {
                        Text(token.account)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignTokens.Colors.success)
                    .font(.title2)
            }

            HStack(spacing: DesignTokens.Spacing.md) {
                Button("Add Token") {
                    Task {
                        try? await vaultService.addToken(token)
                        router.pop()
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AccessibilityID.saveTokenButton)

                Button("Scan Again") {
                    withAnimation(AnimationTokens.quick) {
                        scannedToken = nil
                        isScanning = true
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.large))
    }

    // MARK: - Barcode Handler

    private func handleBarcode(_ payload: String) {
        guard isScanning else { return }
        isScanning = false

        if let token = totpService.parseOTPAuthURL(payload) {
            withAnimation(AnimationTokens.spring) {
                scannedToken = token
            }
        } else {
            errorMessage = "Invalid QR code. Expected an otpauth:// URL."
            showError = true
        }
    }
}

// MARK: - DataScanner UIViewControllerRepresentable

struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onBarcodeFound: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        if !controller.isScanning {
            try? controller.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeFound: onBarcodeFound)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onBarcodeFound: (String) -> Void
        private var lastScanned: String?

        init(onBarcodeFound: @escaping (String) -> Void) {
            self.onBarcodeFound = onBarcodeFound
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for item in addedItems {
                if case .barcode(let barcode) = item,
                   let payload = barcode.payloadStringValue,
                   payload != lastScanned {
                    lastScanned = payload
                    onBarcodeFound(payload)
                }
            }
        }
    }
}
