// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "narration-pilot",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(
            name: "NarrationPilot",
            targets: ["NarrationPilot"]
        ),
    ],
    dependencies: [
        .package(path: "Vendor/KeyboardShortcuts"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "NarrationPilot",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ]
        ),
        .testTarget(
            name: "NarrationPilotTests",
            dependencies: ["NarrationPilot"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
