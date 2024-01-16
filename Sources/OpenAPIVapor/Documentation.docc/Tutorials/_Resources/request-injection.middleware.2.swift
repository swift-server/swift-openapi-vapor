import Vapor
import Dependencies

struct OpenAPIRequestInjectionMiddleware: AsyncMiddleware {
    func respond(
        to request: Request,
        chainingTo responder: AsyncResponder
    ) async throws -> Response {
        try await withDependencies {
            $0.request = request
        } operation: {
            try await responder.respond(to: request)
        }
    }
}
