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
import Vapor
import NIOFoundationCompat

public final class VaporTransport {

    /// A routes builder with which to register request handlers.
    internal var routesBuilder: any Vapor.RoutesBuilder

    /// Creates a new transport.
    /// - Parameter routesBuilder: A routes builder with which to register request handlers.
    public init(routesBuilder: any Vapor.RoutesBuilder) {
        self.routesBuilder = routesBuilder
    }
}

extension VaporTransport: ServerTransport {
    public func register(
        _ handler: @Sendable @escaping (OpenAPIRuntime.Request, OpenAPIRuntime.ServerRequestMetadata)
        async throws -> OpenAPIRuntime.Response,
        method: OpenAPIRuntime.HTTPMethod,
        path: [RouterPathComponent],
        queryItemNames: Set<String>
    ) throws {
        self.routesBuilder.on(
            HTTPMethod(method),
            path.map(Vapor.PathComponent.init(_:))
        ) { vaporRequest in
            let request = try await OpenAPIRuntime.Request(vaporRequest)
            let requestMetadata = try OpenAPIRuntime.ServerRequestMetadata(
                from: vaporRequest,
                forPath: path,
                extractingQueryItemNamed: queryItemNames
            )
            let response = try await handler(request, requestMetadata)
            return Vapor.Response(response)
        }
    }
}

enum VaporTransportError: Error {
    case unsupportedHTTPMethod(String)
    case duplicatePathParameter([String])
    case missingRequiredPathParameter(String)
}

extension Vapor.PathComponent {
    init(_ pathComponent: OpenAPIRuntime.RouterPathComponent) {
        switch pathComponent {
        case .constant(let value): self = .constant(value)
        case .parameter(let value): self = .parameter(value)
        }
    }
}

extension OpenAPIRuntime.Request {
    init(_ vaporRequest: Vapor.Request) async throws {
        let headerFields: [OpenAPIRuntime.HeaderField] = .init(vaporRequest.headers)

        let bodyData = Data(buffer: try await vaporRequest.body.collect(upTo: .max), byteTransferStrategy: .noCopy)

        let method = try OpenAPIRuntime.HTTPMethod(vaporRequest.method)

        self.init(
            path: vaporRequest.url.path,
            query: vaporRequest.url.query,
            method: method,
            headerFields: headerFields,
            body: bodyData
        )
    }
}

extension OpenAPIRuntime.ServerRequestMetadata {
    init(
        from vaporRequest: Vapor.Request,
        forPath path: [RouterPathComponent],
        extractingQueryItemNamed queryItemNames: Set<String>
    ) throws {
        self.init(
            pathParameters: try .init(from: vaporRequest, forPath: path),
            queryParameters: .init(from: vaporRequest, queryItemNames: queryItemNames)
        )
    }
}

extension Dictionary where Key == String, Value == String {
    init(from vaporRequest: Vapor.Request, forPath path: [RouterPathComponent]) throws {
        let keysAndValues = try path.compactMap { item -> (String, String)? in
            guard case let .parameter(name) = item else {
                return nil
            }
            guard let value = vaporRequest.parameters.get(name) else {
                throw VaporTransportError.missingRequiredPathParameter(name)
            }
            return (name, value)
        }
        let pathParameterDictionary = try Dictionary(keysAndValues, uniquingKeysWith: { _, _ in
            throw VaporTransportError.duplicatePathParameter(keysAndValues.map(\.0))
        })
        self = pathParameterDictionary
    }
}

extension Array where Element == URLQueryItem {
    init(from vaporRequest: Vapor.Request, queryItemNames: Set<String>) {
        let queryParameters = queryItemNames.sorted().compactMap { name -> URLQueryItem? in
            guard let value = try? vaporRequest.query.get(String.self, at: name) else {
                return nil
            }
            return .init(name: name, value: value)
        }
        self = queryParameters
    }
}

extension Vapor.Response {
    convenience init(_ response: OpenAPIRuntime.Response) {
        self.init(
            status: .init(statusCode: response.statusCode),
            headers: .init(response.headerFields),
            body: .init(data: response.body)
        )
    }
}

extension Array where Element == OpenAPIRuntime.HeaderField {
    init(_ headers: NIOHTTP1.HTTPHeaders) {
        self = headers.map { .init(name: $0.name, value: $0.value) }
    }
}

extension NIOHTTP1.HTTPHeaders {
    init(_ headers: [OpenAPIRuntime.HeaderField]) {
        self.init(headers.map { ($0.name, $0.value) })
    }
}

extension OpenAPIRuntime.HTTPMethod {
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
    init(_ method: OpenAPIRuntime.HTTPMethod) {
        switch method {
        case .get: self = .GET
        case .put: self = .PUT
        case .post: self = .POST
        case .delete: self = .DELETE
        case .options: self = .OPTIONS
        case .head: self = .HEAD
        case .patch: self = .PATCH
        case .trace: self = .TRACE
        default: self = .RAW(value: method.name)
        }
    }
}
