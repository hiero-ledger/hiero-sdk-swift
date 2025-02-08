// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Delete a file or smart contract - can only be done with a Hedera admin.
public final class SystemDeleteTransaction: Transaction {
    /// Create a new `SystemDeleteTransaction`.
    public init(
        fileId: FileId? = nil,
        contractId: ContractId? = nil,
        expirationTime: Timestamp? = nil
    ) {
        self.fileId = fileId
        self.contractId = contractId
        self.expirationTime = expirationTime

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_SystemDeleteTransactionBody) throws {
        switch data.id {
        case .contractID(let contractId):
            self.contractId = try .fromProtobuf(contractId)
        case .fileID(let fileId):
            self.fileId = .fromProtobuf(fileId)
        case nil:
            break
        }

        self.expirationTime =
            data.hasExpirationTime ? .init(seconds: UInt64(data.expirationTime.seconds), subSecondNanos: 0) : nil

        try super.init(protobuf: proto)
    }

    /// The file ID which should be deleted.
    public var fileId: FileId? {
        willSet {
            ensureNotFrozen(fieldName: "fileId")
        }
    }

    /// Sets the file ID which should be deleted.
    @discardableResult
    public func fileId(_ fileId: FileId) -> Self {
        self.fileId = fileId

        return self
    }

    /// The contract ID which should be deleted.
    public var contractId: ContractId? {
        willSet {
            ensureNotFrozen(fieldName: "contractId")
        }
    }

    /// Sets the contract ID which should be deleted.
    @discardableResult
    public func contractId(_ contractId: ContractId) -> Self {
        self.contractId = contractId

        return self
    }

    /// The timestamp at which the "deleted" file should
    /// truly be permanently deleted.
    public var expirationTime: Timestamp? {
        willSet {
            ensureNotFrozen(fieldName: "expirationTime")
        }
    }

    /// Sets the timestamp at which the "deleted" file should
    /// truly be permanently deleted.
    @discardableResult
    public func expirationTime(_ expirationTime: Timestamp) -> Self {
        self.expirationTime = expirationTime

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try fileId?.validateChecksums(on: ledgerId)
        try contractId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        if fileId != nil {
            return try await Proto_FileServiceAsyncClient(channel: channel).systemDelete(request)
        }

        if contractId != nil {
            return try await Proto_SmartContractServiceAsyncClient(channel: channel).systemDelete(request)
        }

        fatalError("\(type(of: self)) has no `fileId`/`contractId`")
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .systemDelete(
            .with { proto in
                if let fileId = fileId {
                    proto.fileID = fileId.toProtobuf()
                }

                if let contractId = contractId {
                    proto.contractID = contractId.toProtobuf()
                }

                if let expirationTime = expirationTime {
                    proto.expirationTime = .with { $0.seconds = Int64(expirationTime.seconds) }
                }
            }
        )
    }
}

extension SystemDeleteTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_SystemDeleteTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            if let fileId = fileId {
                proto.fileID = fileId.toProtobuf()
            }

            if let contractId = contractId {
                proto.contractID = contractId.toProtobuf()
            }

            if let expirationTime = expirationTime {
                proto.expirationTime = .with { $0.seconds = Int64(expirationTime.seconds) }
            }
        }
    }
}

extension SystemDeleteTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .systemDelete(toProtobuf())
    }
}
