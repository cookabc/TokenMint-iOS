# TokenMint

A clean and elegant TOTP authenticator for iOS, providing a secure, touch-first two-factor authentication experience. Built with SwiftUI and Liquid Glass design.

## Features

- **AES-256-GCM Encryption** — tokens stored in encrypted vault with iOS Keychain key management
- **Biometric Unlock** — Face ID / Touch ID with passcode fallback
- **QR Code Scanning** — `DataScannerViewController` for instant account setup
- **Manual Entry** — add tokens by entering secret key and account details
- **One-Tap Copy** — tap to copy current TOTP code with haptic feedback
- **Pin Favorites** — pin frequently used tokens to the top
- **Search** — instant filtering across all accounts
- **Import/Export** — JSON vault backup and restore
- **Settings** — haptic toggle, theme selection, vault management
- **Accessibility** — full VoiceOver support with labels, hints, and identifiers on all interactive elements
- **Localization** — English and Simplified Chinese (`Localizable.xcstrings`)
- **Privacy** — `PrivacyInfo.xcprivacy` declares all data usage

## Tech Stack

| Item | Detail |
|------|--------|
| Language | Swift 6.2 (`SWIFT_STRICT_CONCURRENCY = complete`) |
| UI | SwiftUI 7 (Liquid Glass) |
| Target | iOS 26.0+ |
| Persistence | AES-256-GCM encrypted file + iOS Keychain |
| Architecture | MVVM — `@Observable @MainActor` ViewModels, protocol-based DI |
| Concurrency | Structured Concurrency only (`Task.sleep` timer, no Combine) |
| Testing | Swift Testing (unit) + XCTest (UI), 33 unit + 7 UI = **40 tests** |
| Build System | Tuist (`Project.swift` → `.xcodeproj`) |

## Getting Started

```bash
# Generate Xcode project (requires Tuist)
curl -Ls https://install.tuist.io | bash
tuist generate

# Or build directly
tuist build
# Select iPhone 17 Pro simulator → Cmd+R
```

## Project Structure

```
App/
├── TokenMintApp.swift            # Entry point, VaultService initialization
├── PrivacyInfo.xcprivacy
└── Assets.xcassets/

Core/
├── Constants/
│   ├── DesignTokens.swift        # Colors, fonts, spacing, sizes
│   ├── AnimationTokens.swift     # Animation curves & durations
│   └── HapticTokens.swift        # Haptic feedback types
├── Extensions/
│   ├── Color+Extensions.swift
│   └── View+Extensions.swift
├── Models/
│   ├── Token.swift               # TOTP token model (Sendable, Codable)
│   └── TOTPService.swift         # RFC 6238 TOTP generation
├── Navigation/
│   └── Router.swift              # @Observable @MainActor Router
├── Protocols/                    # VaultService, VaultRepository, Keychain, Biometric, Haptic
├── Repositories/
│   └── VaultRepository.swift     # Encrypted file I/O
├── Services/
│   ├── VaultService.swift        # Primary ViewModel — decrypt, manage, auto-save
│   ├── KeychainService.swift     # iOS Keychain wrapper
│   ├── BiometricService.swift    # Face ID / Touch ID
│   └── HapticService.swift       # User-toggleable haptic feedback
└── Utils/
    ├── Accessibility.swift       # Label / Hint / Identifier enums
    ├── AppError.swift            # Unified error enum
    ├── ViewState.swift           # ViewState<T> generic
    └── Logger.swift              # os.Logger wrapper

Features/
├── TokenList/                    # Token list, row with countdown ring, swipe actions
├── AddToken/                     # Manual token entry form
├── Scanner/                      # QR code scanning (DataScannerViewController)
├── LockScreen/                   # Biometric / passcode lock
└── Settings/                     # Preferences, import/export, vault management

Resources/
├── Localizable.xcstrings        # en + zh-Hans
└── PreviewContent/

Tests/
├── UnitTests/                   # TOTPService, VaultService, Router & Model
└── UITests/                     # Full flow UI tests
```

## Architecture Decisions

- **No `@unchecked Sendable`** — all types properly Sendable or actor-isolated
- **No singletons** — all services protocol-based with constructor injection
- **No Combine** — `Task.sleep` for TOTP countdown timer, no `Timer.publish`
- **No `DispatchQueue`** — pure Structured Concurrency
- **No `NavigationView` / `@EnvironmentObject`** — `NavigationStack` + `@Environment`
- **`DesignTokens.swift`** — zero inline magic numbers
- **Encrypted vault** — SwiftData not used (no built-in encryption for TOTP secrets)

## License

Private
