import OpenAPIVapor
import Dependencies

struct MyAPIProtocolImpl: APIProtocol {
    @Dependency(\.request) var request

    func myOpenAPIEndpointFunction() async throws -> Operations.myOperation.Output {
        /// Use `request` as if this is a normal Vapor endpoint function
        request.logger.notice(
            "Got a request!",
            metadata: [
                "request": .stringConvertible(request)
            ]
        )
    }
}
