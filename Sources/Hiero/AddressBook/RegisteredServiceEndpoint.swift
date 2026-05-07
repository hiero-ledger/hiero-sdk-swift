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
///     endpointApis: [.subscribeStream]
/// )
/// ```
public enum RegisteredServiceEndpoint {
    /// A block node endpoint.
    case blockNode(BlockNodeServiceEndpoint)

    /// A mirror node endpoint.
    case mirrorNode(MirrorNodeServiceEndpoint)

    /// An RPC relay endpoint.
    case rpcRelay(RpcRelayServiceEndpoint)

    /// A general service endpoint for any network-accessible service not otherwise defined
    /// as part of the Hiero Ledger system.
    case generalService(GeneralServiceEndpoint)

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
        endpointApis: [BlockNodeApi] = []
    ) -> RegisteredServiceEndpoint {
        .blockNode(
            BlockNodeServiceEndpoint(
                address: address, port: port, requiresTls: requiresTls, endpointApis: endpointApis))
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

    /// Create a general service endpoint.
    public static func generalService(
        address: Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false,
        description: String? = nil
    ) -> RegisteredServiceEndpoint {
        .generalService(
            GeneralServiceEndpoint(
                address: address, port: port, requiresTls: requiresTls, description: description))
    }
}

// MARK: - Concrete endpoint types

/// A service endpoint for a block node.
///
/// Block nodes store the block chain, provide content proof services, and deliver
/// the block stream to other clients. Each endpoint declares which well-known
/// block node APIs it exposes via `endpointApis`.
public struct BlockNodeServiceEndpoint {
    /// The address of this endpoint (IP or FQDN).
    public var address: RegisteredServiceEndpoint.Address?

    /// The network port.
    public var port: UInt32

    /// Whether this endpoint requires TLS.
    public var requiresTls: Bool

    /// The block node APIs exposed by this endpoint.
    public var endpointApis: [BlockNodeApi]

    /// Creates a block node service endpoint with the given parameters.
    public init(
        address: RegisteredServiceEndpoint.Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false,
        endpointApis: [BlockNodeApi] = []
    ) {
        self.address = address
        self.port = port
        self.requiresTls = requiresTls
        self.endpointApis = endpointApis
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

    /// Creates a mirror node service endpoint with the given parameters.
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

    /// Creates an RPC relay service endpoint with the given parameters.
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

/// A service endpoint for any network-accessible service not otherwise defined as part of
/// the Hiero Ledger system. Use this for custom or experimental services.
public struct GeneralServiceEndpoint {
    /// The address of this endpoint (IP or FQDN).
    public var address: RegisteredServiceEndpoint.Address?

    /// The network port.
    public var port: UInt32

    /// Whether this endpoint requires TLS.
    public var requiresTls: Bool

    /// Optional short description of the service (max 100 bytes UTF-8).
    public var description: String?

    /// Creates a general service endpoint with the given parameters.
    public init(
        address: RegisteredServiceEndpoint.Address? = nil,
        port: UInt32 = 0,
        requiresTls: Bool = false,
        description: String? = nil
    ) {
        self.address = address
        self.port = port
        self.requiresTls = requiresTls
        self.description = description
    }
}

// MARK: - Protobuf

extension RegisteredServiceEndpoint: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Addressbook_RegisteredServiceEndpoint

    private static func parseAddress(from proto: Protobuf) -> Address? {
        switch proto.address {
        case .ipAddress(let data): return .ipAddress(data)
        case .domainName(let name): return .domainName(name)
        case nil: return nil
        }
    }

    internal init(protobuf proto: Protobuf) throws {
        let address = Self.parseAddress(from: proto)
        let port = proto.port
        let requiresTls = proto.requiresTls

        switch proto.endpointType {
        case .blockNode(let endpoint):
            self = .blockNode(
                BlockNodeServiceEndpoint(
                    address: address,
                    port: port,
                    requiresTls: requiresTls,
                    endpointApis: try endpoint.endpointApi.map { try .fromProtobuf($0) }
                ))
        case .mirrorNode:
            self = .mirrorNode(MirrorNodeServiceEndpoint(address: address, port: port, requiresTls: requiresTls))
        case .rpcRelay:
            self = .rpcRelay(RpcRelayServiceEndpoint(address: address, port: port, requiresTls: requiresTls))
        case .generalService(let endpoint):
            self = .generalService(
                GeneralServiceEndpoint(
                    address: address,
                    port: port,
                    requiresTls: requiresTls,
                    description: endpoint.description_p.isEmpty ? nil : endpoint.description_p
                ))
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
                proto.blockNode = .with { $0.endpointApi = endpoint.endpointApis.map { $0.toProtobuf() } }
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
            case .generalService(let endpoint):
                applyAddress(endpoint.address)
                proto.port = endpoint.port
                proto.requiresTls = endpoint.requiresTls
                proto.generalService = .with { gs in
                    if let desc = endpoint.description { gs.description_p = desc }
                }
            }
        }
    }
}
