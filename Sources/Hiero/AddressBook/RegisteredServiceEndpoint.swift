// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// A registered network node endpoint.
///
/// Each registered network node publishes one or more endpoints which enable
/// the nodes to communicate with clients. An endpoint declares an address
/// (IP or FQDN), port, TLS requirement, and the type of node service it provides.
public struct RegisteredServiceEndpoint {
    /// The address of this endpoint (IP or FQDN). Mutually exclusive.
    public var address: Address?

    /// The network port.
    public var port: UInt32 = 0

    /// Whether this endpoint requires TLS.
    public var requiresTls: Bool = false

    /// The type of service this endpoint provides.
    public var endpointType: EndpointType

    /// An IP address or fully qualified domain name (mutually exclusive).
    public enum Address {
        /// A 32-bit IPv4 address or 128-bit IPv6 address in big-endian byte order.
        case ipAddress(Data)

        /// A fully qualified domain name.
        case domainName(String)
    }

    /// The type of registered node service endpoint.
    public enum EndpointType {
        /// A block node endpoint exposing the given API.
        case blockNode(BlockNodeApi)

        /// A mirror node endpoint.
        case mirrorNode

        /// An RPC relay endpoint.
        case rpcRelay
    }

    public init(
        address: Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false,
        endpointType: EndpointType
    ) {
        self.address = address
        self.port = port
        self.requiresTls = requiresTls
        self.endpointType = endpointType
    }

    /// Create a block node service endpoint.
    public static func blockNode(
        address: Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false,
        endpointApi: BlockNodeApi = .other
    ) -> RegisteredServiceEndpoint {
        RegisteredServiceEndpoint(
            address: address,
            port: port,
            requiresTls: requiresTls,
            endpointType: .blockNode(endpointApi)
        )
    }
}

extension RegisteredServiceEndpoint: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Addressbook_RegisteredServiceEndpoint

    internal init(protobuf proto: Protobuf) throws {
        switch proto.address {
        case .ipAddress(let data):
            self.address = .ipAddress(data)
        case .domainName(let name):
            self.address = .domainName(name)
        case nil:
            self.address = nil
        }

        self.port = proto.port
        self.requiresTls = proto.requiresTls

        switch proto.endpointType {
        case .blockNode(let blockNodeEndpoint):
            self.endpointType = .blockNode(try .fromProtobuf(blockNodeEndpoint.endpointApi))
        case .mirrorNode:
            self.endpointType = .mirrorNode
        case .rpcRelay:
            self.endpointType = .rpcRelay
        case nil:
            throw HError.fromProtobuf("RegisteredServiceEndpoint missing endpoint_type")
        }
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            switch address {
            case .ipAddress(let data):
                proto.ipAddress = data
            case .domainName(let name):
                proto.domainName = name
            case nil:
                break
            }

            proto.port = port
            proto.requiresTls = requiresTls

            switch endpointType {
            case .blockNode(let api):
                proto.blockNode = .with { $0.endpointApi = api.toProtobuf() }
            case .mirrorNode:
                proto.mirrorNode = .init()
            case .rpcRelay:
                proto.rpcRelay = .init()
            }
        }
    }
}
