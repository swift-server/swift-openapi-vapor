import OpenAPIRuntime
import OpenAPIVapor
import Vapor

// ...

let app = Vapor.Application()

let requestInjectionMiddleware = OpenAPIRequestInjectionMiddleware()
let transport = VaporTransport(routesBuilder: app.grouped(requestInjectionMiddleware))

let handler = MyAPIProtocolImpl()

try handler.registerHandlers(on: transport, serverURL: Servers.server1())

// ...
