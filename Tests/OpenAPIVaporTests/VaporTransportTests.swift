import XCTVapor
@testable import OpenAPIVapor
import OpenAPIRuntime

final class VaporTransportTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = Application(.testing)
    }

    override func tearDown() async throws {
        app.shutdown()
    }

    func testRequestConversion() async throws {
        // POST /hello/{name}
        app.post("hello", ":name") { vaporRequest in
            // Hijack the request handler to test the request-conversion functions.
            let expectedRequest = Request(
                path: "/hello/Maria",
                query: "greeting=Howdy",
                method: .post,
                headerFields: [
                    .init(name: "X-Mumble", value: "mumble"),
                    .init(name: "content-length", value: "4")
                ],
                body: Data("👋".utf8)
            )
            let expectedRequestMetadata = ServerRequestMetadata(
                pathParameters: [ "name": "Maria" ],
                queryParameters: [ URLQueryItem(name: "greeting", value: "Howdy") ]
            )
            let request = try await Request(vaporRequest)
            XCTAssertEqual(request, expectedRequest)
            XCTAssertEqual(
                try ServerRequestMetadata(
                    from: vaporRequest,
                    forPath: [.constant("hello"), .parameter("name")],
                    extractingQueryItemNamed: ["greeting"]
                ),
                expectedRequestMetadata
            )

            // Use the response-conversion to create the Vapor response for returning.
            let response = Response(
                statusCode: 201,
                headerFields: [
                    .init(name: "X-Mumble", value: "mumble")
                ],
                body: Data("👋".utf8)
            )
            return Vapor.Response(response)
        }

        try app.test(
            .POST,
            "/hello/Maria?greeting=Howdy",
            headers: ["X-Mumble": "mumble"],
            body: ByteBuffer(string: "👋"),
            afterResponse: { response in
                XCTAssertEqual(response.status.code, 201)
            }
        )
    }

    func testHandlerRegistration() throws {
        let transport = VaporTransport(routesBuilder: app)
        try transport.register({ _, _  in OpenAPIRuntime.Response(statusCode: 201) },
            method: .post,
            path: [.constant("hello"), .parameter("name")],
            queryItemNames: ["greeting"]
        )
        try app.test(
            .POST,
            "/hello/Maria?greeting=Howdy",
            headers: ["X-Mumble": "mumble"],
            body: ByteBuffer(string: "👋"),
            afterResponse: { response in
                XCTAssertEqual(response.status.code, 201)
            }
        )
    }

    func testHTTPMethodConversion() throws {
        XCTAssert(function: NIOHTTP1.HTTPMethod.init(_:), behavesAccordingTo: [
            (.get, .GET),
            (.put, .PUT),
            (.post, .POST),
            (.delete, .DELETE),
            (.options, .OPTIONS),
            (.head, .HEAD),
            (.patch, .PATCH),
            (.trace, .TRACE)
        ])
        try XCTAssert(function: OpenAPIRuntime.HTTPMethod.init(_:), behavesAccordingTo: [
            (.GET, .get),
            (.PUT, .put),
            (.POST, .post),
            (.DELETE, .delete),
            (.OPTIONS, .options),
            (.HEAD, .head),
            (.PATCH, .patch),
            (.TRACE, .trace)
        ])
    }
}

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
