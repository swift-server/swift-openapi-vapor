// swift-tools-version: 5.9

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
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
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", .upToNextMinor(from: "0.3.0")),
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
