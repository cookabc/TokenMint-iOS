# TokenMint for iOS

TokenMint is a clean and elegant TOTP authenticator, providing a native touch-first experience on iOS.

## Design Philosophy
TokenMint iOS aims to provide a "Clean and Elegant" experience, mirroring the macOS version but adapted for touch interactions. The design focuses on readability, ease of access, and secure management of 2FA tokens.

## Features (Phase 1)
*   🔐 **Secure Storage**: AES-256 (AES.GCM) encryption using iOS Keychain for key management.
*   📱 **Native UI**: Built with SwiftUI for smooth performance.
*   📋 **One-Tap Copy**: Quickly copy verification codes with haptic feedback.
*   🔍 **Search**: Filter your accounts instantly.
*   📝 **Manual Entry**: Add accounts by entering the secret key.

## Architecture & Data Flow
*   **MVVM Pattern**: Uses `VaultService` as the primary ViewModel.
*   **Data Flow**:
    1.  `TokenMintApp` initializes `VaultService`.
    2.  `VaultService` decrypts `vault.enc` from Application Support.
    3.  User actions update the vault, which auto-saves to disk.

## Project Structure
The source code is located in `TokenMint/`:
*   `TokenMintApp.swift`: Application entry point and lifecycle.
*   `Views/`: SwiftUI views and UI components.
*   `Models/`: Shared data models (Token, Vault).
*   `Services/`: Core business logic (TOTP, Vault, Keychain).
*   `Utilities/`: Helpers and localization.

## Requirements
*   iOS 17.0+
*   Xcode 16.0+
*   Swift 5.0+

## Building
1.  Open `TokenMint.xcodeproj` in Xcode.
2.  Ensure all files are added to the target.
3.  Build and Run on the iOS Simulator or Device.
