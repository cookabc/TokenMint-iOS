# TokenMint (iOS)

A clean and elegant TOTP authenticator for iOS. Built with SwiftUI and Liquid Glass design.

## Features

- **AES-256-GCM Encryption** — tokens stored in encrypted vault with iOS Keychain key management
- **Biometric Unlock** — Face ID / Touch ID with passcode fallback
- **QR Code Scanning** — DataScannerViewController for instant account setup
- **Manual Entry** — add tokens by entering secret key and account details
- **One-Tap Copy** — tap to copy current TOTP code with haptic feedback
- **Pin Favorites** — pin frequently used tokens to the top
- **Search** — instant filtering across all accounts
- **Import/Export** — JSON vault backup and restore
- **Settings** — haptic toggle, theme selection, vault management
- **Accessibility** — full VoiceOver support with labels, hints, and identifiers on all interactive elements
- **Localization** — English and Simplified Chinese

## Tech Stack

| Item         | Detail                                                        |
| ------------ | ------------------------------------------------------------- |
| Language     | Swift 6.2 (`SWIFT_STRICT_CONCURRENCY = complete`)             |
| UI           | SwiftUI (Liquid Glass)                                        |
| Target       | iOS 16.0+                                                     |
| Architecture | MVVM — `@Observable @MainActor` ViewModels, protocol-based DI |
| Security     | AES-256-GCM encryption + Keychain                             |
| Biometric    | LocalAuthentication framework                                 |
| Camera       | DataScannerViewController (iOS 16+)                           |
| State        | @Observable (SwiftUI Observation)                             |
| Linting      | SwiftLint with strict configuration                           |
| Build System | Tuist (`Project.swift` → `.xcodeproj`)                        |

## Getting Started

```bash
# Generate Xcode project (requires Tuist)
curl -Ls https://install.tuist.io | bash
tuist generate

# Or build directly
tuist build
# Select iPhone simulator → Cmd+R
```

## Project Structure

```
App/
├── TokenMintApp.swift            # Entry point
├── PrivacyInfo.xcprivacy
└── Assets.xcassets/

Core/
├── Constants/
│   ├── DesignTokens.swift        # Colors, fonts, spacing
│   ├── AnimationTokens.swift     # Animation curves & durations
│   └── HapticTokens.swift        # Haptic feedback types
├── Models/                       # Token, Vault data models
├── Navigation/
│   └── Router.swift              # @Observable @MainActor Router
├── Protocols/                    # Service interfaces
├── Services/
│   ├── KeychainService.swift     # Keychain encryption
│   ├── TOTPService.swift         # TOTP generation
│   └── BiometricService.swift    # Face ID / Touch ID
├── Utils/                        # Utilities
└── Extensions/                   # View extensions

Features/
├── TokenList/                    # Main token list
├── AddToken/                     # Add token manually
├── Scanner/                      # QR code scanner
├── LockScreen/                   # Biometric lock
└── Settings/                     # Preferences

Tests/
├── UnitTests/                    # Service and model tests
└── UITests/                      # Full flow UI tests
```

## Security

- Vault encrypted with AES-256-GCM via iOS Keychain
- Face ID / Touch ID required on app launch
- Clipboard cleared when app goes to background

## License

Private
