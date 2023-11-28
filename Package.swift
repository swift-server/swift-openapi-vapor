// swift-tools-version: 5.9

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    /// https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md
    /// Require `any` for existential types.
    .enableUpcomingFeature("ExistentialAny"),
    /// Introduced in Swift 5.9, enables strict concurrency checks as planned for Swift 6.
    /// Accepted values are `minimal`, `targeted` and `complete`.
    /// `minimal` is the default in all projects, if not specified.
    .enableExperimentalFeature("StrictConcurrency=complete"),
]

let package = Package(
    name: "swift-openapi-vapor",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "OpenAPIVapor", targets: ["OpenAPIVapor"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", exact: "1.0.0-alpha.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.86.2"),
        .package(url: "https://github.com/apple/swift-atomics", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "OpenAPIVapor",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Atomics", package: "swift-atomics")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "OpenAPIVaporTests",
            dependencies: [
                "OpenAPIVapor",
                .product(name: "XCTVapor", package: "vapor")
            ],
            swiftSettings: swiftSettings
        )
    ]
)
