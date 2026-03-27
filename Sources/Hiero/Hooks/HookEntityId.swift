// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs

/// Identifies the entity that owns a hook.
///
/// An entity can be either an account or a contract. Exactly one of `accountId` or `contractId`
/// should be set.
public struct HookEntityId {
    /// The ID of the account that owns the hook, if the owner is an account.
    public var accountId: AccountId?

    /// The ID of the contract that owns the hook, if the owner is a contract.
    public var contractId: ContractId?

    /// Create a new `HookEntityId` with no owner set.
    public init() {}

    /// Create a new `HookEntityId` with an account owner.
    public init(accountId: AccountId) {
        self.accountId = accountId
    }

    /// Create a new `HookEntityId` with a contract owner.
    public init(contractId: ContractId) {
        self.contractId = contractId
    }

    /// Sets the owning account ID, clearing any contract ID.
    @discardableResult
    public mutating func accountId(_ accountId: AccountId) -> Self {
        self.accountId = accountId
        self.contractId = nil
        return self
    }

    /// Sets the owning contract ID, clearing any account ID.
    @discardableResult
    public mutating func contractId(_ contractId: ContractId) -> Self {
        self.contractId = contractId
        self.accountId = nil
        return self
    }
}

extension HookEntityId: TryProtobufCodable {
    internal typealias Protobuf = Proto_HookEntityId

    internal init(protobuf proto: Protobuf) throws {
        self.init()
        switch proto.entityID {
        case .accountID(let id):
            self.accountId = try AccountId.fromProtobuf(id)
        case .contractID(let id):
            self.contractId = try ContractId.fromProtobuf(id)
        case nil:
            break
        }
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            if let id = accountId {
                proto.entityID = .accountID(id.toProtobuf())
            } else if let id = contractId {
                proto.entityID = .contractID(id.toProtobuf())
            }
        }
    }
}

extension HookEntityId: ValidateChecksums {
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try accountId?.validateChecksums(on: ledgerId)
        try contractId?.validateChecksums(on: ledgerId)
    }
}
