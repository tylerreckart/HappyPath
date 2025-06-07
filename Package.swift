// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HappyPath",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "HappyPath",
            targets: ["HappyPath"]),
    ],
    targets: [
        .target(
            name: "HappyPath"),
        .testTarget(
            name: "HappyPathTests",
            dependencies: ["HappyPath"]),
    ]
)
