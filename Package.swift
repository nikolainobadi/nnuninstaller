// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "nnuninstaller",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "nnuninstaller",
            targets: ["nnuninstaller"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nikolainobadi/NnShellKit.git", from: "1.0.0"),
        .package(url: "https://github.com/nikolainobadi/SwiftPicker.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "nnuninstaller",
            dependencies: [
                "NnShellKit",
                "SwiftPicker",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "nnuninstallerTests",
            dependencies: ["nnuninstaller"]
        ),
    ]
)
