// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs

public final class HookEntityId {
    /// ID of the account that owns a hook.
    public var accountId: AccountId? = nil

    /// ID of the contract that owns a hook.
    public var contractId: ContractId? = nil

    public init() {}

    public init(accountId: AccountId) {
        self.accountId = accountId
    }

    public init(contractId: ContractId) {
        self.contractId = contractId
    }

    /// Sets the ID of the account that owns a hook.
    @discardableResult
    public func accountId(_ accountId: AccountId) -> Self {
        self.accountId = accountId
        self.contractId = nil
        return self
    }

    /// Sets the ID of the contract that owns a hook.
    @discardableResult
    public func contractId(_ contractId: ContractId) -> Self {
        self.contractId = contractId
        self.accountId = nil
        return self
    }
}

extension HookEntityId: TryProtobufCodable {
    internal typealias Protobuf = Proto_HookEntityId

    internal convenience init(protobuf proto: Protobuf) throws {
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
