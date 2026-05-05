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

    public init() {}

    /// Execute this query and return all registered nodes from the mirror node.
    public func execute(_ client: Client) async throws -> RegisteredNodeAddressBook {
        let mirrorNetworkAddress = client.mirrorNetwork[0]
        let endpoint = "/api/v1/network/registered-nodes"

        let hostPart = String(mirrorNetworkAddress.split(separator: ":")[0])
        let isLocal = hostPart == "localhost" || hostPart == "127.0.0.1"

        let urlString =
            isLocal
            ? "http://\(mirrorNetworkAddress)\(endpoint)"
            : "https://\(mirrorNetworkAddress)\(endpoint)"

        guard let url = URL(string: urlString) else {
            throw HError.basicParse("Invalid mirror node URL: \(urlString)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        #if canImport(FoundationNetworking)
            let (data, response): (Data, URLResponse) = try await withCheckedThrowingContinuation {
                continuation in
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

        let decoded = try JSONDecoder().decode(MirrorRegisteredNodesResponse.self, from: data)
        let nodes = try decoded.registered_nodes.map { try RegisteredNode(mirror: $0) }
        return RegisteredNodeAddressBook(registeredNodes: nodes)
    }
}

// MARK: - Private mirror node JSON types

private struct MirrorRegisteredNodesResponse: Decodable {
    let registered_nodes: [MirrorRegisteredNode]
}

private struct MirrorRegisteredNode: Decodable {
    let registered_node_id: UInt64
    let admin_key: MirrorKey
    let description: String?
    let service_endpoints: [MirrorServiceEndpoint]
}

private struct MirrorKey: Decodable {
    let key: String
}

private struct MirrorServiceEndpoint: Decodable {
    let ip_address: String?
    let domain_name: String?
    let port: UInt32
    let requires_tls: Bool
    let type: String
    let general_service: MirrorGeneralService?
}

private struct MirrorGeneralService: Decodable {
    let description: String?
}

// MARK: - RegisteredNode mirror init

extension RegisteredNode {
    fileprivate init(mirror node: MirrorRegisteredNode) throws {
        guard let keyBytes = Data(hexEncoded: node.admin_key.key) else {
            throw HError.basicParse("Invalid hex in admin_key: \(node.admin_key.key)")
        }
        let protoKey = try Proto_Key(serializedBytes: keyBytes)
        let adminKey = try Key.fromProtobuf(protoKey)
        let endpoints = try node.service_endpoints.map { try RegisteredServiceEndpoint(mirror: $0) }
        self.init(
            registeredNodeId: node.registered_node_id,
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
        if let ip = endpoint.ip_address, !ip.isEmpty {
            guard let ipData = Self.parseIpv4(ip) else {
                throw HError.basicParse("Invalid IP address in registered service endpoint: \(ip)")
            }
            address = .ipAddress(ipData)
        } else if let domain = endpoint.domain_name, !domain.isEmpty {
            address = .domainName(domain)
        } else {
            address = nil
        }

        switch endpoint.type {
        case "BLOCK_NODE":
            // endpoint_apis is not yet returned by the mirror node REST API
            self = .blockNode(
                BlockNodeServiceEndpoint(
                    address: address, port: endpoint.port, requiresTls: endpoint.requires_tls,
                    endpointApis: []))
        case "MIRROR_NODE":
            self = .mirrorNode(
                MirrorNodeServiceEndpoint(
                    address: address, port: endpoint.port, requiresTls: endpoint.requires_tls))
        case "RPC_RELAY":
            self = .rpcRelay(
                RpcRelayServiceEndpoint(
                    address: address, port: endpoint.port, requiresTls: endpoint.requires_tls))
        case "GENERAL_SERVICE":
            self = .generalService(
                GeneralServiceEndpoint(
                    address: address, port: endpoint.port, requiresTls: endpoint.requires_tls,
                    description: endpoint.general_service?.description))
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
