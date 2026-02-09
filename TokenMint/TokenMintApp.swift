//
//  TokenMintApp.swift
//  TokenMint
//
//  Created by 宋许刚 on 2026/2/6.
//

import SwiftUI

@main
struct TokenMintApp: App {
    init() {
        _ = VaultService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(VaultService.shared)
        }
    }
}
