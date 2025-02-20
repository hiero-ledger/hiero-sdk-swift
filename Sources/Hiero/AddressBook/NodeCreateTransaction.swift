/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

/// A transaction body to add a new consensus node to the network address book.
///
/// This transaction body SHALL be considered a "privileged transaction".
///
/// This message supports a transaction to create a new node in the network
/// address book. The transaction, once complete, enables a new consensus node
/// to join the network, and requires governing council authorization.
///
/// - A `NodeCreateTransactionBody` MUST be signed by the governing council.
/// - A `NodeCreateTransactionBody` MUST be signed by the `Key` assigned to the
///   `admin_key` field.
/// - The newly created node information SHALL be added to the network address
///   book information in the network state.
/// - The new entry SHALL be created in "state" but SHALL NOT participate in
///   network consensus and SHALL NOT be present in network "configuration"
///   until the next "upgrade" transaction (as noted below).
/// - All new address book entries SHALL be added to the active network
///   configuration during the next `freeze` transaction with the field
///   `freeze_type` set to `PREPARE_UPGRADE`.
///
public final class NodeCreateTransaction: Transaction {
    public init(
        accountId: AccountId? = nil,
        description: String = "",
        gossipEndpoints: [Endpoint] = [],
        serviceEndpoints: [Endpoint] = [],
        gossipCaCertificate: Data? = nil,
        grpcCertificateHash: Data? = nil,
        adminKey: Key? = nil
    ) {
        self.accountId = accountId
        self.description = description
        self.gossipEndpoints = gossipEndpoints
        self.serviceEndpoints = serviceEndpoints
        self.gossipCaCertificate = gossipCaCertificate
        self.grpcCertificateHash = grpcCertificateHash
        self.adminKey = adminKey

        super.init()
    }

    internal init(
        protobuf proto: Proto_TransactionBody, _ data: Com_Hedera_Hapi_Node_Addressbook_NodeCreateTransactionBody
    ) throws {
        self.accountId = data.hasAccountID ? try .fromProtobuf(data.accountID) : nil
        self.description = data.description_p
        self.gossipEndpoints = try data.gossipEndpoint.map(Endpoint.init)
        self.serviceEndpoints = try data.serviceEndpoint.map(Endpoint.init)
        self.gossipCaCertificate = data.gossipCaCertificate
        self.grpcCertificateHash = data.grpcCertificateHash
        self.adminKey = data.hasAdminKey ? try .fromProtobuf(data.adminKey) : nil

        try super.init(protobuf: proto)
    }

    /// Node account ID.
    public var accountId: AccountId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the node account
    @discardableResult
    public func accountId(_ accountId: AccountId?) -> Self {
        self.accountId = accountId

        return self
    }

    /// Returns the nodes description.
    public var description: String {
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

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try accountId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_AddressBookServiceAsyncClient(channel: channel).createNode(request)
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .nodeCreate(toProtobuf())
    }
}

extension NodeCreateTransaction: ToProtobuf {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Addressbook_NodeCreateTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            accountId?.toProtobufInto(&proto.accountID)
            proto.description_p = description
            proto.gossipEndpoint = gossipEndpoints.map { $0.toProtobuf() }
            proto.serviceEndpoint = serviceEndpoints.map { $0.toProtobuf() }
            proto.gossipCaCertificate = gossipCaCertificate ?? Data()
            proto.grpcCertificateHash = grpcCertificateHash ?? Data()
            if let adminKey = adminKey {
                proto.adminKey = adminKey.toProtobuf()
            }
        }
    }
}

extension NodeCreateTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .nodeCreate(toProtobuf())
    }
}
