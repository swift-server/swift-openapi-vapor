# Swift OpenAPI Vapor

This package provides Vapor Bindings for the [OpenAPI generator](https://github.com/apple/swift-openapi-generator).

## Usage

In `entrypoint.swift` add:

```swift
// Create a Vapor OpenAPI Transport using your application.
let transport = VaporOpenAPITransport(app)

// Create an instance of your handler type that conforms the generated protocol
// defining your service API.
let handler = MyServiceAPIImpl()

// Call the generated function on your implementation to add its request
// handlers to the app.
try handler.registerHandlers(on: transport, serverURL: Servers.server1())
```

## Documentation

To get started, check out the full [documentation][docs-generator], which contains step-by-step tutorials!

[docs-generator]: https://swiftpackageindex.com/apple/swift-openapi-generator/documentation