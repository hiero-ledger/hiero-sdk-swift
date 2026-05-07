// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

/// A transaction body to update an existing registered node in the network address book.
///
/// Must be signed by the registered node's current `adminKey`. If `adminKey` is
/// being changed, both the old and new key must sign.
///
/// When `serviceEndpoints` is set to a non-empty list, it replaces the existing
/// endpoint list entirely. When left empty (the default), the existing endpoints
/// are unchanged.
public final class RegisteredNodeUpdateTransaction: Transaction {
    public init(
        registeredNodeId: UInt64 = 0,
        adminKey: Key? = nil,
        description: String? = nil,
        serviceEndpoints: [RegisteredServiceEndpoint] = []
    ) {
        self.registeredNodeId = registeredNodeId
        self.adminKey = adminKey
        self.description = description
        self.serviceEndpoints = serviceEndpoints

        super.init()
    }

    internal init(
        protobuf proto: Proto_TransactionBody,
        _ data: Com_Hedera_Hapi_Node_Addressbook_RegisteredNodeUpdateTransactionBody
    ) throws {
        self.registeredNodeId = data.registeredNodeID
        self.adminKey = data.hasAdminKey ? try .fromProtobuf(data.adminKey) : nil
        self.description = data.hasDescription_p ? data.description_p.value : nil
        self.serviceEndpoints = try data.serviceEndpoint.map { try .fromProtobuf($0) }

        try super.init(protobuf: proto)
    }

    /// The ID of the registered node to update.
    public var registeredNodeId: UInt64 {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the registered node ID to update.
    @discardableResult
    public func registeredNodeId(_ registeredNodeId: UInt64) -> Self {
        self.registeredNodeId = registeredNodeId

        return self
    }

    /// An administrative key controlled by the node operator.
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

    /// The updated registered node description.
    public var description: String? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the registered node's description.
    @discardableResult
    public func description(_ description: String) -> Self {
        self.description = description

        return self
    }

    /// The list of service endpoints for this registered node.
    public var serviceEndpoints: [RegisteredServiceEndpoint] {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the list of service endpoints for this registered node.
    @discardableResult
    public func serviceEndpoints(_ serviceEndpoints: [RegisteredServiceEndpoint]) -> Self {
        self.serviceEndpoints = serviceEndpoints

        return self
    }

    /// Add a service endpoint to the list.
    @discardableResult
    public func addServiceEndpoint(_ serviceEndpoint: RegisteredServiceEndpoint) -> Self {
        self.serviceEndpoints.append(serviceEndpoint)

        return self
    }

    internal override func transactionExecute(
        _ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval
    ) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_AddressBookServiceAsyncClient(channel: channel).updateRegisteredNode(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .registeredNodeUpdate(toProtobuf())
    }
}

extension RegisteredNodeUpdateTransaction: ToProtobuf {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Addressbook_RegisteredNodeUpdateTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.registeredNodeID = registeredNodeId

            if let adminKey = adminKey {
                proto.adminKey = adminKey.toProtobuf()
            }

            if let description = description {
                proto.description_p = Google_Protobuf_StringValue(description)
            }

            proto.serviceEndpoint = serviceEndpoints.map { $0.toProtobuf() }
        }
    }
}

extension RegisteredNodeUpdateTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .registeredNodeUpdate(toProtobuf())
    }
}
