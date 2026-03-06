import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.app(
    name: "TokenMint",
    bundleId: "com.chuangcius.tokenMint",
    displayName: "TokenMint",
    infoPlist: [
        "NSCameraUsageDescription": "Camera is needed to scan QR codes for adding tokens",
        "NSFaceIDUsageDescription": "Face ID is used to protect your vault",
    ],
    testSources: ["Tests/UnitTests/**", "Tests/IntegrationTests/**"]
)
