// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

/// A transaction body to create a new registered node in the network address book.
///
/// Upon success, the receipt contains the `registeredNodeId` of the newly created
/// registered node. The `adminKey` must sign this transaction.
public final class RegisteredNodeCreateTransaction: Transaction {
    public init(
        adminKey: Key? = nil,
        description: String? = nil,
        serviceEndpoints: [RegisteredServiceEndpoint] = []
    ) {
        self.adminKey = adminKey
        self.description = description
        self.serviceEndpoints = serviceEndpoints

        super.init()
    }

    internal init(
        protobuf proto: Proto_TransactionBody,
        _ data: Com_Hedera_Hapi_Node_Addressbook_RegisteredNodeCreateTransactionBody
    ) throws {
        self.adminKey = data.hasAdminKey ? try .fromProtobuf(data.adminKey) : nil
        self.description = !data.description_p.isEmpty ? data.description_p : nil
        self.serviceEndpoints = try data.serviceEndpoint.map { try .fromProtobuf($0) }

        try super.init(protobuf: proto)
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

    /// The registered node's description.
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

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(
        _ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval
    ) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_AddressBookServiceAsyncClient(channel: channel).createRegisteredNode(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .registeredNodeCreate(toProtobuf())
    }
}

extension RegisteredNodeCreateTransaction: ToProtobuf {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Addressbook_RegisteredNodeCreateTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            if let adminKey = adminKey {
                proto.adminKey = adminKey.toProtobuf()
            }
            proto.description_p = description ?? ""
            proto.serviceEndpoint = serviceEndpoints.map { $0.toProtobuf() }
        }
    }
}

extension RegisteredNodeCreateTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .registeredNodeCreate(toProtobuf())
    }
}
