// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// A registered network node service endpoint.
///
/// Each registered network node publishes one or more endpoints which enable
/// clients to connect to the node. An endpoint is one of three concrete types
/// — block node, mirror node, or RPC relay — each carrying common address/port/TLS
/// fields plus any type-specific fields defined by the endpoint's HIP.
///
/// Use the convenience factory methods to construct an endpoint:
/// ```swift
/// let endpoint = RegisteredServiceEndpoint.blockNode(
///     address: .ipAddress(Data([127, 0, 0, 1])),
///     port: 8080,
///     requiresTls: true,
///     endpointApi: .subscribeStream
/// )
/// ```
public enum RegisteredServiceEndpoint {
    /// A block node endpoint.
    case blockNode(BlockNodeServiceEndpoint)

    /// A mirror node endpoint.
    case mirrorNode(MirrorNodeServiceEndpoint)

    /// An RPC relay endpoint.
    case rpcRelay(RpcRelayServiceEndpoint)

    /// An IP address or fully qualified domain name (mutually exclusive).
    public enum Address {
        /// A 32-bit IPv4 address or 128-bit IPv6 address in big-endian byte order.
        case ipAddress(Data)

        /// A fully qualified domain name (max 250 ASCII characters).
        case domainName(String)
    }

    // MARK: - Convenience factories

    /// Create a block node service endpoint.
    public static func blockNode(
        address: Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false,
        endpointApi: BlockNodeApi = .other
    ) -> RegisteredServiceEndpoint {
        .blockNode(
            BlockNodeServiceEndpoint(
                address: address, port: port, requiresTls: requiresTls, endpointApi: endpointApi))
    }

    /// Create a mirror node service endpoint.
    public static func mirrorNode(
        address: Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false
    ) -> RegisteredServiceEndpoint {
        .mirrorNode(MirrorNodeServiceEndpoint(address: address, port: port, requiresTls: requiresTls))
    }

    /// Create an RPC relay service endpoint.
    public static func rpcRelay(
        address: Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false
    ) -> RegisteredServiceEndpoint {
        .rpcRelay(RpcRelayServiceEndpoint(address: address, port: port, requiresTls: requiresTls))
    }
}

// MARK: - Concrete endpoint types

/// A service endpoint for a block node.
///
/// Block nodes store the block chain, provide content proof services, and deliver
/// the block stream to other clients. Each endpoint declares which well-known
/// block node API it exposes via `endpointApi`.
public struct BlockNodeServiceEndpoint {
    /// The address of this endpoint (IP or FQDN).
    public var address: RegisteredServiceEndpoint.Address?

    /// The network port.
    public var port: UInt32

    /// Whether this endpoint requires TLS.
    public var requiresTls: Bool

    /// The block node API exposed by this endpoint.
    public var endpointApi: BlockNodeApi

    public init(
        address: RegisteredServiceEndpoint.Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false,
        endpointApi: BlockNodeApi = .other
    ) {
        self.address = address
        self.port = port
        self.requiresTls = requiresTls
        self.endpointApi = endpointApi
    }
}

/// A service endpoint for a mirror node.
///
/// Mirror nodes provide fast and flexible access to query the block chain and
/// transaction history. Currently carries no type-specific fields; additional
/// fields may be added in future HIPs without restructuring the endpoint hierarchy.
public struct MirrorNodeServiceEndpoint {
    /// The address of this endpoint (IP or FQDN).
    public var address: RegisteredServiceEndpoint.Address?

    /// The network port.
    public var port: UInt32

    /// Whether this endpoint requires TLS.
    public var requiresTls: Bool

    public init(
        address: RegisteredServiceEndpoint.Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false
    ) {
        self.address = address
        self.port = port
        self.requiresTls = requiresTls
    }
}

/// A service endpoint for an RPC relay.
///
/// RPC relays act as a proxy and translator between EVM tooling and a Hiero
/// consensus network. Currently carries no type-specific fields; additional
/// fields may be added in future HIPs without restructuring the endpoint hierarchy.
public struct RpcRelayServiceEndpoint {
    /// The address of this endpoint (IP or FQDN).
    public var address: RegisteredServiceEndpoint.Address?

    /// The network port.
    public var port: UInt32

    /// Whether this endpoint requires TLS.
    public var requiresTls: Bool

    public init(
        address: RegisteredServiceEndpoint.Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false
    ) {
        self.address = address
        self.port = port
        self.requiresTls = requiresTls
    }
}

// MARK: - Protobuf

extension RegisteredServiceEndpoint: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Addressbook_RegisteredServiceEndpoint

    internal init(protobuf proto: Protobuf) throws {
        let address: Address?
        switch proto.address {
        case .ipAddress(let data): address = .ipAddress(data)
        case .domainName(let name): address = .domainName(name)
        case nil: address = nil
        }

        let port = proto.port
        let requiresTls = proto.requiresTls

        switch proto.endpointType {
        case .blockNode(let endpoint):
            self = .blockNode(
                BlockNodeServiceEndpoint(
                    address: address,
                    port: port,
                    requiresTls: requiresTls,
                    endpointApi: try .fromProtobuf(endpoint.endpointApi)
                ))
        case .mirrorNode:
            self = .mirrorNode(MirrorNodeServiceEndpoint(address: address, port: port, requiresTls: requiresTls))
        case .rpcRelay:
            self = .rpcRelay(RpcRelayServiceEndpoint(address: address, port: port, requiresTls: requiresTls))
        case nil:
            throw HError.fromProtobuf("RegisteredServiceEndpoint missing endpoint_type")
        }
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            func applyAddress(_ address: Address?) {
                switch address {
                case .ipAddress(let data): proto.ipAddress = data
                case .domainName(let name): proto.domainName = name
                case nil: break
                }
            }

            switch self {
            case .blockNode(let endpoint):
                applyAddress(endpoint.address)
                proto.port = endpoint.port
                proto.requiresTls = endpoint.requiresTls
                proto.blockNode = .with { $0.endpointApi = endpoint.endpointApi.toProtobuf() }
            case .mirrorNode(let endpoint):
                applyAddress(endpoint.address)
                proto.port = endpoint.port
                proto.requiresTls = endpoint.requiresTls
                proto.mirrorNode = .init()
            case .rpcRelay(let endpoint):
                applyAddress(endpoint.address)
                proto.port = endpoint.port
                proto.requiresTls = endpoint.requiresTls
                proto.rpcRelay = .init()
            }
        }
    }
}
