// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "clipboard-reader-mac",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(
            name: "clipboard-reader-mac",
            targets: ["clipboard-reader-mac"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "1.9.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "clipboard-reader-mac",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ]
        ),
        .testTarget(
            name: "clipboard-reader-macTests",
            dependencies: ["clipboard-reader-mac"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
