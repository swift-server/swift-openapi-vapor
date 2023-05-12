// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "swift-openapi-vapor",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "OpenAPIVapor", targets: ["OpenAPIVapor"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "OpenAPIVapor",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ]
        ),
        .testTarget(
            name: "OpenAPIVaporTests",
            dependencies: [
                "OpenAPIVapor",
                .product(name: "XCTVapor", package: "vapor")
            ]
        )
    ]
)
