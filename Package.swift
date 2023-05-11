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
        .library(name: "VaporOpenAPIRuntime", targets: ["VaporOpenAPIRuntime"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", branch: "main"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "VaporOpenAPIRuntime",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ]
        ),
        .testTarget(
            name: "VaporOpenAPIRuntimeTests",
            dependencies: [
                "VaporOpenAPIRuntime",
                .product(name: "XCTVapor", package: "vapor")
            ]
        )
    ]
)
