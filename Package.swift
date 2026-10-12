// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SettingsPane",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "SettingsPane", targets: ["SettingsPane"]),
    ],
    targets: [
        .target(name: "SettingsPane"),
        .testTarget(name: "SettingsPaneTests", dependencies: ["SettingsPane"]),
    ]
)
