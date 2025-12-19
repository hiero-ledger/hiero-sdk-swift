// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

/// Transaction body to modify address book node attributes.
///
/// - This transaction SHALL enable the node operator, as identified by the
///   `admin_key`, to modify operational attributes of the node.
/// - This transaction MUST be signed by the active `admin_key` for the node.
/// - If this transaction sets a new value for the `admin_key`, then both the
///   current `admin_key`, and the new `admin_key` MUST sign this transaction.
/// - This transaction SHALL NOT change any field that is not set (is null) in
///   this transaction body.
/// - This SHALL create a pending update to the node, but the change SHALL NOT
///   be immediately applied to the active configuration.
/// - All pending node updates SHALL be applied to the active network
///   configuration during the next `freeze` transaction with the field
///   `freeze_type` set to `PREPARE_UPGRADE`.
public final class NodeUpdateTransaction: Transaction {
    public init(
        nodeId: UInt64 = 0,
        accountId: AccountId? = nil,
        description: String? = nil,
        gossipEndpoints: [Endpoint] = [],
        serviceEndpoints: [Endpoint] = [],
        gossipCaCertificate: Data? = nil,
        grpcCertificateHash: Data? = nil,
        adminKey: Key? = nil,
        grpcWebProxyEndpoint: Endpoint? = nil,
        declineRewards: Bool? = nil
    ) {
        self.nodeId = nodeId
        self.accountId = accountId
        self.description = description
        self.gossipEndpoints = gossipEndpoints
        self.serviceEndpoints = serviceEndpoints
        self.gossipCaCertificate = gossipCaCertificate
        self.grpcCertificateHash = grpcCertificateHash
        self.adminKey = adminKey
        self.grpcWebProxyEndpoint = grpcWebProxyEndpoint
        self.declineRewards = declineRewards

        super.init()
    }

    internal init(
        protobuf proto: Proto_TransactionBody, _ data: Com_Hedera_Hapi_Node_Addressbook_NodeUpdateTransactionBody
    ) throws {
        self.nodeId = data.nodeID
        self.accountId = data.hasAccountID ? try .fromProtobuf(data.accountID) : nil
        self.description = data.hasDescription_p ? data.description_p.value : nil
        self.gossipEndpoints = try data.gossipEndpoint.map(Endpoint.init)
        self.serviceEndpoints = try data.serviceEndpoint.map(Endpoint.init)
        self.gossipCaCertificate = data.hasGossipCaCertificate ? data.gossipCaCertificate.value : nil
        self.grpcCertificateHash = data.hasGrpcCertificateHash ? data.grpcCertificateHash.value : nil
        self.adminKey = data.hasAdminKey ? try .fromProtobuf(data.adminKey) : nil
        self.grpcWebProxyEndpoint = data.hasGrpcProxyEndpoint ? try Endpoint(protobuf: data.grpcProxyEndpoint) : nil
        self.declineRewards = data.hasDeclineReward ? data.declineReward.value : nil

        try super.init(protobuf: proto)
    }

    /// Node index to update.
    public var nodeId: UInt64? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the node index to update.
    @discardableResult
    public func nodeId(_ nodeId: UInt64) -> Self {
        self.nodeId = nodeId

        return self
    }

    /// Node account ID.
    public var accountId: AccountId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the node account Id.
    @discardableResult
    public func accountId(_ accountId: AccountId) -> Self {
        self.accountId = accountId

        return self
    }

    /// Returns the updated node description.
    public var description: String? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the node's description.
    @discardableResult
    public func description(_ description: String) -> Self {
        self.description = description

        return self
    }

    /// A list of service endpoints for gossip.
    public var gossipEndpoints: [Endpoint] {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Assign the list of service endpoints for gossip.
    @discardableResult
    public func gossipEndpoints(_ gossipEndpoints: [Endpoint]) -> Self {
        self.gossipEndpoints = gossipEndpoints

        return self
    }

    /// Add an endpoint for gossip to the list of service endpoints for gossip.
    @discardableResult
    public func addGossipEndpoint(_ gossipEndpoint: Endpoint) -> Self {
        self.gossipEndpoints.append(gossipEndpoint)

        return self
    }

    /// Extract the list of service endpoints for gRPC calls.
    public var serviceEndpoints: [Endpoint] {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Assign the list of service endpoints for gRPC calls.
    @discardableResult
    public func serviceEndpoints(_ serviceEndpoints: [Endpoint]) -> Self {
        self.serviceEndpoints = serviceEndpoints

        return self
    }

    /// Add an endpoint for gRPC calls to the list of service endpoints for gRPC calls.
    @discardableResult
    public func addServiceEndpoint(_ serviceEndpoint: Endpoint) -> Self {
        self.serviceEndpoints.append(serviceEndpoint)

        return self
    }

    /// Extract the gRPC web proxy endpoint.
    public var grpcWebProxyEndpoint: Endpoint? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the gRPC web proxy endpoint.
    @discardableResult
    public func grpcWebProxyEndpoint(_ grpcWebProxyEndpoint: Endpoint) -> Self {
        self.grpcWebProxyEndpoint = grpcWebProxyEndpoint

        return self
    }

    /// Extract the certificate used to sign gossip events.
    public var gossipCaCertificate: Data? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the certificate used to sign gossip events.
    @discardableResult
    public func gossipCaCertificate(_ gossipCaCertificate: Data) -> Self {
        self.gossipCaCertificate = gossipCaCertificate

        return self
    }

    /// Extract the hash of the node gRPC TLS certificate.
    public var grpcCertificateHash: Data? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the hash of the node gRPC TLS certificate.
    @discardableResult
    public func grpcCertificateHash(_ grpcCertificateHash: Data) -> Self {
        self.grpcCertificateHash = grpcCertificateHash

        return self
    }

    /// Get an administrative key controlled by the node operator.
    public var adminKey: Key? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets an administrative key controlled by the node operator.
    @discardableResult
    public func adminKey(_ adminKey: Key) -> Self {
        self.adminKey = adminKey

        return self
    }

    /// Should this node decline staking rewards?
    public var declineRewards: Bool? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the staking rewards policy for the node.
    @discardableResult
    public func declineRewards(_ declineRewards: Bool) -> Self {
        self.declineRewards = declineRewards

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try accountId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_AddressBookServiceAsyncClient(channel: channel).updateNode(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .nodeUpdate(toProtobuf())
    }
}

extension NodeUpdateTransaction: ToProtobuf {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Addressbook_NodeUpdateTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.nodeID = nodeId ?? 0
            accountId?.toProtobufInto(&proto.accountID)
            proto.gossipEndpoint = gossipEndpoints.map { $0.toProtobuf() }
            proto.serviceEndpoint = serviceEndpoints.map { $0.toProtobuf() }

            if let gossipCaCertificate = gossipCaCertificate {
                proto.gossipCaCertificate = Google_Protobuf_BytesValue(gossipCaCertificate)
            }

            if let grpcCertificateHash = grpcCertificateHash {
                proto.grpcCertificateHash = Google_Protobuf_BytesValue(grpcCertificateHash)
            }

            if let description = description {
                proto.description_p = Google_Protobuf_StringValue(description)
            }

            if let adminKey = adminKey {
                proto.adminKey = adminKey.toProtobuf()
            }

            if let grpcWebProxyEndpoint = grpcWebProxyEndpoint {
                proto.grpcProxyEndpoint = grpcWebProxyEndpoint.toProtobuf()
            }

            if let declineRewards = declineRewards {
                proto.declineReward = Google_Protobuf_BoolValue(declineRewards)
            }
        }
    }
}

extension NodeUpdateTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .nodeUpdate(toProtobuf())
    }
}
