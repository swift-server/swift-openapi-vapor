import Vapor
import OpenAPIRuntime

enum Streaming {

#if compiler(>=5.9)
    @available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
    actor Writer {
        let unownedExecutor: UnownedSerialExecutor
        let writer: any Vapor.BodyStreamWriter
        let body: OpenAPIRuntime.HTTPBody

        init(
            writer: any Vapor.BodyStreamWriter,
            body: OpenAPIRuntime.HTTPBody
        ) {
            self.unownedExecutor = writer.eventLoop.executor.asUnownedSerialExecutor()
            self.writer = writer
            self.body = body
        }

        func write() async {
            do {
                for try await chunk in body {
                    try await writer.write(.buffer(ByteBuffer(bytes: chunk))).get()
                }
                try await writer.write(.end).get()
            } catch {
                try? await writer.write(.error(error)).get()
            }
        }
    }
#endif // compiler(>=5.9)

    static func write(
        body: OpenAPIRuntime.HTTPBody,
        writer: any Vapor.BodyStreamWriter
    ) async {
#if compiler(>=5.9)
        if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) {
            await Writer(writer: writer, body: body).write()
            return
        }
#endif // compiler(>=5.9)
        await _writeWithHops(body: body, writer: writer)
    }

    static func _writeWithHops(
        body: OpenAPIRuntime.HTTPBody,
        writer: any Vapor.BodyStreamWriter
    ) async {
        do {
            for try await chunk in body {
                try await writer.eventLoop.flatSubmit {
                    writer.write(.buffer(ByteBuffer(bytes: chunk)))
                }.get()
            }
            try await writer.eventLoop.flatSubmit {
                writer.write(.end)
            }.get()
        } catch {
            try? await writer.eventLoop.flatSubmit {
                writer.write(.error(error))
            }.get()
        }
    }
}
