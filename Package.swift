// swift-tools-version: 5.8

import PackageDescription

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
