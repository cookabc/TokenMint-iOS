import ProjectDescription

public enum AppSchemeConfig {
    case debug
    case release
}

public extension Project {
    /// Factory for a standard single-module iOS app with unit + UI test targets.
    static func app(
        name: String,
        bundleId: String,
        displayName: String? = nil,
        infoPlist: [String: Plist.Value] = [:],
        testSources: SourceFilesList = ["Tests/UnitTests/**"],
        schemeConfig: AppSchemeConfig = .release
    ) -> Project {
        // Merge app-specific plist entries with shared defaults
        var plist: [String: Plist.Value] = [
            "UILaunchScreen": .dictionary([:]),
            "UISupportedInterfaceOrientations": [
                "UIInterfaceOrientationPortrait",
                "UIInterfaceOrientationLandscapeLeft",
                "UIInterfaceOrientationLandscapeRight",
            ],
            "UISupportedInterfaceOrientations~iPad": [
                "UIInterfaceOrientationPortrait",
                "UIInterfaceOrientationPortraitUpsideDown",
                "UIInterfaceOrientationLandscapeLeft",
                "UIInterfaceOrientationLandscapeRight",
            ],
        ]
        if let displayName { plist["CFBundleDisplayName"] = .string(displayName) }
        plist.merge(infoPlist) { _, new in new }

        let configuration: ConfigurationName = schemeConfig == .debug ? .debug : .release

        // Optimization configs (only for release-based projects)
        let appConfigurations: [Configuration] = schemeConfig == .release
            ? [
                .debug(name: "Debug", settings: ["SWIFT_OPTIMIZATION_LEVEL": "-Onone"]),
                .release(name: "Release", settings: ["SWIFT_OPTIMIZATION_LEVEL": "-O"]),
            ]
            : []

        return Project(
            name: name,
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.2",
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                ]
            ),
            targets: [
                .target(
                    name: name,
                    destinations: .iOS,
                    product: .app,
                    bundleId: bundleId,
                    deploymentTargets: .iOS("26.0"),
                    infoPlist: .extendingDefault(with: plist),
                    sources: ["App/**", "Core/**", "Features/**"],
                    resources: [
                        "App/Assets.xcassets",
                        "App/PrivacyInfo.xcprivacy",
                        "Resources/Localizable.xcstrings",
                    ],
                    settings: .settings(
                        base: [
                            "CURRENT_PROJECT_VERSION": "1",
                            "MARKETING_VERSION": "1.0",
                            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                        ],
                        configurations: appConfigurations
                    )
                ),
                .target(
                    name: "\(name)Tests",
                    destinations: .iOS,
                    product: .unitTests,
                    bundleId: "\(bundleId).tests",
                    deploymentTargets: .iOS("26.0"),
                    sources: testSources,
                    dependencies: [.target(name: name)]
                ),
                .target(
                    name: "\(name)UITests",
                    destinations: .iOS,
                    product: .uiTests,
                    bundleId: "\(bundleId).uitests",
                    deploymentTargets: .iOS("26.0"),
                    sources: ["Tests/UITests/**"],
                    dependencies: [.target(name: name)]
                ),
            ],
            schemes: [
                .scheme(
                    name: name,
                    buildAction: .buildAction(targets: [.init(stringLiteral: name)]),
                    testAction: .targets(
                        [
                            .init(stringLiteral: "\(name)Tests"),
                            .init(stringLiteral: "\(name)UITests"),
                        ],
                        configuration: configuration
                    ),
                    runAction: .runAction(configuration: configuration),
                    archiveAction: .archiveAction(configuration: .release),
                    profileAction: .profileAction(configuration: .release),
                    analyzeAction: .analyzeAction(configuration: configuration)
                ),
            ]
        )
    }
}
