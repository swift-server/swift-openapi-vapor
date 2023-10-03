import Vapor
import NIOCore
import OpenAPIRuntime

/// Convert ``Vapor.Response.Body`` to an ``AsyncSequence`` of ``HTTPBody.ByteChunks``
struct AsyncStreamerToByteChunkSequence: AsyncSequence {
    typealias Element = OpenAPIRuntime.HTTPBody.ByteChunk

    struct AsyncIterator: AsyncIteratorProtocol {
        var underlyingIterator: Vapor.Request.Body.AsyncIterator

        mutating func next() async throws -> Element? {
            return try await underlyingIterator.next().map { buffer in
                OpenAPIRuntime.HTTPBody.ByteChunk(
                    [UInt8](buffer: buffer)
                )
            }
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        .init(underlyingIterator: self.body.makeAsyncIterator())
    }

    let body: Vapor.Request.Body
}
