// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import SwiftProtobuf

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Queries the mirror node for registered nodes and returns a ``RegisteredNodeAddressBook``.
///
/// Uses the mirror node REST API at `GET /api/v1/network/registered-nodes`.
/// Follows the same REST-over-HTTP pattern as ``MirrorNodeContractQuery``.
public final class RegisteredNodeAddressBookQuery {

    /// Creates a new query instance.
    public init() {}

    /// Execute this query and return all registered nodes from the mirror node.
    public func execute(_ client: Client) async throws -> RegisteredNodeAddressBook {
        let mirrorNetworkAddress = client.mirrorNetwork[0]
        let endpoint = "/api/v1/network/registered-nodes"

        let hostPart = String(mirrorNetworkAddress.split(separator: ":")[0])
        let isLocal = hostPart == "localhost" || hostPart == "127.0.0.1"

        // For local environments, the mirror node REST API runs on port 5551 (not the gRPC port 5600).
        let urlString =
            isLocal
            ? "http://\(hostPart):5551\(endpoint)"
            : "https://\(mirrorNetworkAddress)\(endpoint)"

        guard let url = URL(string: urlString) else {
            throw HError.basicParse("Invalid mirror node URL: \(urlString)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        #if canImport(FoundationNetworking)
            let (data, response): (Data, URLResponse) = try await withCheckedThrowingContinuation { continuation in
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let data = data, let response = response else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                        return
                    }
                    continuation.resume(returning: (data, response))
                }.resume()
            }
        #else
            let (data, response) = try await URLSession.shared.data(for: request)
        #endif

        guard let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw HError.basicParse(
                "Received non-200 response from mirror node: \(statusCode), details: \(body)")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(MirrorRegisteredNodesResponse.self, from: data)
        let nodes = try decoded.registeredNodes.map { try RegisteredNode(mirror: $0) }
        return RegisteredNodeAddressBook(registeredNodes: nodes)
    }
}

// MARK: - Private mirror node JSON types

private struct MirrorRegisteredNodesResponse: Decodable {
    let registeredNodes: [MirrorRegisteredNode]
}

private struct MirrorRegisteredNode: Decodable {
    let registeredNodeId: UInt64
    let adminKey: MirrorKey
    let description: String?
    let serviceEndpoints: [MirrorServiceEndpoint]
}

private struct MirrorKey: Decodable {
    let key: String
}

private struct MirrorServiceEndpoint: Decodable {
    let ipAddress: String?
    let domainName: String?
    let port: UInt32
    let requiresTls: Bool
    let type: String
    let generalService: MirrorGeneralService?
}

private struct MirrorGeneralService: Decodable {
    let description: String?
}

// MARK: - RegisteredNode mirror init

extension RegisteredNode {
    fileprivate init(mirror node: MirrorRegisteredNode) throws {
        guard let keyBytes = Data(hexEncoded: node.adminKey.key) else {
            throw HError.basicParse("Invalid hex in adminKey: \(node.adminKey.key)")
        }
        let protoKey = try Proto_Key(serializedBytes: keyBytes)
        let adminKey = try Key.fromProtobuf(protoKey)
        let endpoints = try node.serviceEndpoints.map { try RegisteredServiceEndpoint(mirror: $0) }
        self.init(
            registeredNodeId: node.registeredNodeId,
            adminKey: adminKey,
            description: node.description,
            serviceEndpoints: endpoints
        )
    }
}

// MARK: - RegisteredServiceEndpoint mirror init

extension RegisteredServiceEndpoint {
    fileprivate init(mirror endpoint: MirrorServiceEndpoint) throws {
        let address: Address?
        if let ip = endpoint.ipAddress, !ip.isEmpty {
            guard let ipData = Self.parseIpv4(ip) else {
                throw HError.basicParse("Invalid IP address in registered service endpoint: \(ip)")
            }
            address = .ipAddress(ipData)
        } else if let domain = endpoint.domainName, !domain.isEmpty {
            address = .domainName(domain)
        } else {
            address = nil
        }

        switch endpoint.type {
        case "BLOCK_NODE":
            // endpoint_apis is not yet returned by the mirror node REST API
            self = .blockNode(
                BlockNodeServiceEndpoint(
                    address: address, port: endpoint.port, requiresTls: endpoint.requiresTls,
                    endpointApis: []))
        case "MIRROR_NODE":
            self = .mirrorNode(
                MirrorNodeServiceEndpoint(
                    address: address, port: endpoint.port, requiresTls: endpoint.requiresTls))
        case "RPC_RELAY":
            self = .rpcRelay(
                RpcRelayServiceEndpoint(
                    address: address, port: endpoint.port, requiresTls: endpoint.requiresTls))
        case "GENERAL_SERVICE":
            self = .generalService(
                GeneralServiceEndpoint(
                    address: address, port: endpoint.port, requiresTls: endpoint.requiresTls,
                    description: endpoint.generalService?.description))
        default:
            throw HError.basicParse("Unknown service endpoint type: \(endpoint.type)")
        }
    }

    private static func parseIpv4(_ ip: String) -> Data? {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(4)
        for part in parts {
            guard let byte = UInt8(part) else { return nil }
            bytes.append(byte)
        }
        return Data(bytes)
    }
}
