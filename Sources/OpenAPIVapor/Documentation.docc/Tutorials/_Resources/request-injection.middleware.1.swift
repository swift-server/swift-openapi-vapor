import Vapor
import Dependencies

struct OpenAPIRequestInjectionMiddleware: AsyncMiddleware {
    func respond(
        to request: Request,
        chainingTo responder: AsyncResponder
    ) async throws -> Response {

    }
}
