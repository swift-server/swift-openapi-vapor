//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenAPI Vapor open source project
//
// Copyright (c) YEARS the Swift OpenAPI Vapor project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift OpenAPI Vapor project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import HTTPTypes
import OpenAPIRuntime
import XCTVapor

@testable import OpenAPIVapor

final class VaporTransportTests: XCTestCase {

  var app: Application!

  override func setUp() async throws {
    app = Application(.testing)
  }

  override func tearDown() async throws {
    app.shutdown()
  }

  func testHeadRequestExplicitContentLength() async throws {
    let transport = VaporTransport(routesBuilder: app)
    let response = HTTPTypes.HTTPResponse(
      status: .ok,
      headerFields: [
        .contentLength: "42"
      ]
    )
    try transport.register(
      { _, _, _ in (response, nil) },
      method: .head,
      path: "/test"
    )
    try app.test(
      .HEAD,
      "/test",
      afterResponse: { response in
        XCTAssertEqual(response.status, .ok)
        let contentLength = response.headers.first(name: .contentLength)
        XCTAssertEqual(contentLength, "42")
      }
    )
  }

  func testRequestConversion() async throws {
    // POST /hello/{name}
    app.post("hello", ":name", "world") { vaporRequest in
      // Hijack the request handler to test the request-conversion functions.
      let expectedRequest = HTTPTypes.HTTPRequest(
        method: .post,
        scheme: nil,
        authority: nil,
        path: "/hello/Maria/world?greeting=Howdy",
        headerFields: [
          HTTPField.Name("X-Mumble")!: "mumble",
          HTTPField.Name("content-length")!: "4",
        ]
      )
      let expectedRequestMetadata = ServerRequestMetadata(
        pathParameters: ["name": "Maria"]
      )
      let request = try HTTPTypes.HTTPRequest(vaporRequest)
      let body = OpenAPIRuntime.HTTPBody(vaporRequest)
      let collectedBody = try await [UInt8](collecting: body, upTo: .max)
      XCTAssertEqual(request, expectedRequest)
      XCTAssertEqual(collectedBody, [UInt8]("👋".utf8))
      XCTAssertEqual(
        try ServerRequestMetadata(
          from: vaporRequest,
          forPath: "/hello/{name}/world"
        ),
        expectedRequestMetadata
      )

      // Use the response-conversion to create the Vapor response for returning.
      let response = HTTPTypes.HTTPResponse(
        status: .created,
        headerFields: [
          HTTPField.Name("X-Mumble")!: "mumble"
        ]
      )
      return Vapor.Response(response: response, body: .init([UInt8]("👋".utf8)))
    }

    try app.test(
      .POST,
      "/hello/Maria/world?greeting=Howdy",
      headers: ["X-Mumble": "mumble"],
      body: ByteBuffer(string: "👋"),
      afterResponse: { response in
        XCTAssertEqual(response.status.code, 201)
      }
    )
  }

  func testHandlerRegistration() throws {
    let transport = VaporTransport(routesBuilder: app)
    let response = HTTPTypes.HTTPResponse(status: .created)
    try transport.register(
      { _, _, _ in (response, nil) },
      method: .post,
      path: "/hello/{name}"
    )

    XCTAssertTrue(app.routes.all.first?.path == ["hello", ":name"])

    try app.test(
      .POST,
      "/hello/Maria?greeting=Howdy",
      headers: ["X-Mumble": "mumble"],
      body: ByteBuffer(string: "👋"),
      afterResponse: { response in
        XCTAssertEqual(response.status, .created)
      }
    )
  }

  func testHTTPMethodConversion() throws {
    XCTAssert(
      function: NIOHTTP1.HTTPMethod.init(_:),
      behavesAccordingTo: [
        (.get, .GET),
        (.put, .PUT),
        (.post, .POST),
        (.delete, .DELETE),
        (.options, .OPTIONS),
        (.head, .HEAD),
        (.patch, .PATCH),
        (.trace, .TRACE),
      ])
    try XCTAssert(
      function: HTTPTypes.HTTPRequest.Method.init(_:),
      behavesAccordingTo: [
        (.GET, .get),
        (.PUT, .put),
        (.POST, .post),
        (.DELETE, .delete),
        (.OPTIONS, .options),
        (.HEAD, .head),
        (.PATCH, .patch),
        (.TRACE, .trace),
      ])
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
private func XCTAssert<Input, Output>(
  function: (Input) throws -> Output,
  behavesAccordingTo expectations: [(Input, Output)],
  file: StaticString = #file,
  line: UInt = #line
) rethrows where Output: Equatable {
  for (input, output) in expectations {
    try XCTAssertEqual(function(input), output, file: file, line: line)
  }
}
