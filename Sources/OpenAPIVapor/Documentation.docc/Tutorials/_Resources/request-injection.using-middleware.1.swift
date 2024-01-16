import Vapor
import OpenAPIRuntime
import OpenAPIVapor

...

let app = Vapor.Application()

let transport = VaporTransport(routesBuilder: app)

let handler = MyAPIProtocolImpl()

try handler.registerHandlers(on: transport, serverURL: Servers.server1())

...
