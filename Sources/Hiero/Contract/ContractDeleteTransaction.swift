// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Marks a contract as deleted and transfers its remaining hBars, if any, to
/// a designated receiver.
public final class ContractDeleteTransaction: Transaction {
    /// Create a new `ContractDeleteTransaction`.
    public init(contractId: ContractId? = nil) {
        self.contractId = contractId

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_ContractDeleteTransactionBody) throws {
        contractId = data.hasContractID ? try .fromProtobuf(data.contractID) : nil

        switch data.obtainers {
        case .transferAccountID(let account):
            obtainer = try .accountId(.fromProtobuf(account))
        case .transferContractID(let contract):
            obtainer = try .contractId(.fromProtobuf(contract))
        case nil:
            obtainer = nil
        }

        try super.init(protobuf: proto)
    }

    private enum Obtainer {
        case accountId(AccountId)
        case contractId(ContractId)

        fileprivate var accountId: AccountId? {
            if case .accountId(let id) = self {
                return id
            }

            return nil
        }

        fileprivate var contractId: ContractId? {
            if case .contractId(let id) = self {
                return id
            }

            return nil
        }
    }

    /// The contract to be deleted.
    public var contractId: ContractId? {
        willSet {
            ensureNotFrozen()
        }
    }

    private var obtainer: Obtainer?

    /// Sets the contract to be deleted.
    @discardableResult
    public func contractId(_ contractId: ContractId) -> Self {
        self.contractId = contractId

        return self
    }

    /// The account ID which will receive all remaining hbars.
    public var transferAccountId: AccountId? {
        get { obtainer?.accountId }
        set(value) {
            ensureNotFrozen()
            // Only update obtainer when value is non-nil to avoid clearing transferContractId
            if let value = value {
                obtainer = .accountId(value)
            }
        }
    }

    /// Sets the account ID which will receive all remaining hbars.
    @discardableResult
    public func transferAccountId(_ transferAccountId: AccountId) -> Self {
        self.transferAccountId = transferAccountId

        return self
    }

    /// The contract ID which will receive all remaining hbars.
    public var transferContractId: ContractId? {
        get { obtainer?.contractId }
        set(value) {
            ensureNotFrozen()
            // Only update obtainer when value is non-nil to avoid clearing transferAccountId
            if let value = value {
                obtainer = .contractId(value)
            }
        }
    }

    /// Sets the contract ID which will receive all remaining hbars.
    @discardableResult
    public func transferContractId(_ transferContractId: ContractId) -> Self {
        self.transferContractId = transferContractId

        return self
    }

    /// If set to true, means this is a "synthetic" system transaction being used to
    /// signal the network to permanently remove this contract from state.
    ///
    /// **IMPORTANT:** This field is reserved for internal system use only.
    /// Setting this to `true` in a user-initiated transaction will result in
    /// `PERMANENT_REMOVAL_REQUIRES_SYSTEM_INITIATION` error.
    public var permanentRemoval: Bool = false {
        willSet { ensureNotFrozen() }
    }

    /// Sets the permanent removal flag.
    @discardableResult
    public func permanentRemoval(_ permanentRemoval: Bool) -> Self {
        self.permanentRemoval = permanentRemoval
        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try contractId?.validateChecksums(on: ledgerId)
        try transferAccountId?.validateChecksums(on: ledgerId)
        try transferContractId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(
        _ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval
    ) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_SmartContractServiceAsyncClient(channel: channel).deleteContract(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .contractDeleteInstance(toProtobuf())
    }
}

extension ContractDeleteTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_ContractDeleteTransactionBody

    internal func toProtobuf() -> Protobuf {

        .with { proto in
            switch obtainer {
            case .accountId(let id):
                proto.transferAccountID = id.toProtobuf()
            case .contractId(let id):
                proto.transferContractID = id.toProtobuf()
            case nil: break

            }

            contractId?.toProtobufInto(&proto.contractID)
            proto.permanentRemoval = permanentRemoval
        }
    }
}

extension ContractDeleteTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .contractDeleteInstance(toProtobuf())
    }
}
