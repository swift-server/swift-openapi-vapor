//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenAPI Vapor open source project
//
// Copyright (c) 2023 the Swift OpenAPI Vapor project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift OpenAPI Vapor project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import OpenAPIRuntime
import HTTPTypes
import Vapor
import NIOFoundationCompat

public final class VaporTransport {

    /// A routes builder with which to register request handlers.
    internal var routesBuilder: Vapor.RoutesBuilder

    /// Creates a new transport.
    /// - Parameter routesBuilder: A routes builder with which to register request handlers.
    public init(routesBuilder: Vapor.RoutesBuilder) {
        self.routesBuilder = routesBuilder
    }
}

extension VaporTransport: ServerTransport {
    public func register(
        _ handler: @Sendable @escaping (
            HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, OpenAPIRuntime.ServerRequestMetadata
        ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?),
        method: HTTPRequest.Method,
        path: String
    ) throws {
        self.routesBuilder.on(
            HTTPMethod(method),
            [PathComponent](path)
        ) { vaporRequest in
            let request = try HTTPTypes.HTTPRequest(vaporRequest)
            let body = OpenAPIRuntime.HTTPBody(vaporRequest)
            let requestMetadata = try OpenAPIRuntime.ServerRequestMetadata(
                from: vaporRequest,
                forPath: path
            )
            let response = try await handler(request, body, requestMetadata)
            return Vapor.Response(response: response.0, body: response.1)
        }
    }
}

enum VaporTransportError: Error {
    case unsupportedHTTPMethod(String)
    case duplicatePathParameter([String])
    case missingRequiredPathParameter(String)
}

extension [Vapor.PathComponent] {
    init(_ path: String) {
        self = path.split(
            separator: "/",
            omittingEmptySubsequences: false
        ).map { parameter in
            if parameter.first == "{", parameter.last == "}" {
                return .parameter(String(parameter.dropFirst().dropLast()))
            } else {
                return .constant(String(parameter))
            }
        }
    }
}

extension HTTPTypes.HTTPRequest {
    init(_ vaporRequest: Vapor.Request) throws {
        let headerFields: HTTPTypes.HTTPFields = .init(vaporRequest.headers)
        let method = try HTTPTypes.HTTPRequest.Method(vaporRequest.method)
        let queries = vaporRequest.url.query.map { "?\($0)" } ?? ""
        self.init(
            method: method,
            scheme: vaporRequest.url.scheme,
            authority: vaporRequest.url.host,
            path: vaporRequest.url.path + queries,
            headerFields: headerFields
        )
    }
}

extension OpenAPIRuntime.HTTPBody {
    convenience init(_ vaporRequest: Vapor.Request) {
        let contentLength = vaporRequest.headers.first(name: "content-length").map(Int.init)
        self.init(
            vaporRequest.body.map(\.readableBytesView),
            length: contentLength?.map { .known($0) } ?? .unknown,
            iterationBehavior: .single
        )
    }
}

extension OpenAPIRuntime.ServerRequestMetadata {
    init(from vaporRequest: Vapor.Request, forPath path: String) throws {
        self.init(pathParameters: try .init(from: vaporRequest, forPath: path))
    }
}

extension Dictionary<String, Substring> {
    init(from vaporRequest: Vapor.Request, forPath path: String) throws {
        let keysAndValues = try [PathComponent](path).compactMap { component throws -> String? in
            guard case let .parameter(parameter) = component else {
                return nil
            }
            return parameter
        }.map { parameter -> (String, Substring) in
            guard let value = vaporRequest.parameters.get(parameter) else {
                throw VaporTransportError.missingRequiredPathParameter(parameter)
            }
            return (parameter, Substring(value))
        }
        let pathParameterDictionary = try Dictionary(keysAndValues, uniquingKeysWith: { _, _ in
            throw VaporTransportError.duplicatePathParameter(keysAndValues.map(\.0))
        })
        self = pathParameterDictionary
    }
}

extension Vapor.Response {
    convenience init(response: HTTPTypes.HTTPResponse, body: OpenAPIRuntime.HTTPBody?) {
        self.init(
            status: .init(statusCode: response.status.code),
            headers: .init(response.headerFields),
            body: .init(body)
        )
    }
}

extension Vapor.Response.Body {
    init(_ body: OpenAPIRuntime.HTTPBody?) {
        guard let body else {
            self = .empty
            return
        }
        let stream: @Sendable (any Vapor.BodyStreamWriter) -> () = { writer in
            _ = writer.eventLoop.makeFutureWithTask {
                await Streaming.write(body: body, writer: writer)
            }
        }
        switch body.length {
        case let .known(count):
            self = .init(stream: stream, count: count)
        case .unknown:
            self = .init(stream: stream)
        }
    }
}

extension HTTPTypes.HTTPFields {
    init(_ headers: NIOHTTP1.HTTPHeaders) {
        self.init(headers.compactMap { name, value in
            guard let name = HTTPField.Name(name) else {
                return nil
            }
            return HTTPField(name: name, value: value)
        })
    }
}

extension NIOHTTP1.HTTPHeaders {
    init(_ headers: HTTPTypes.HTTPFields) {
        self.init(headers.map { ($0.name.rawName, $0.value) })
    }
}

extension HTTPTypes.HTTPRequest.Method {
    init(_ method: NIOHTTP1.HTTPMethod) throws {
        switch method {
        case .GET: self = .get
        case .PUT: self = .put
        case .POST: self = .post
        case .DELETE: self = .delete
        case .OPTIONS: self = .options
        case .HEAD: self = .head
        case .PATCH: self = .patch
        case .TRACE: self = .trace
        default: throw VaporTransportError.unsupportedHTTPMethod(method.rawValue)
        }
    }
}

extension NIOHTTP1.HTTPMethod {
    init(_ method: HTTPTypes.HTTPRequest.Method) {
        switch method {
        case .get: self = .GET
        case .put: self = .PUT
        case .post: self = .POST
        case .delete: self = .DELETE
        case .options: self = .OPTIONS
        case .head: self = .HEAD
        case .patch: self = .PATCH
        case .trace: self = .TRACE
        default: self = .RAW(value: method.rawValue)
        }
    }
}
