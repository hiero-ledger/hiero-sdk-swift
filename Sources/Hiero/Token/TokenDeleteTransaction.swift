// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Marks a token as deleted, though it will remain in the ledger.
public final class TokenDeleteTransaction: Transaction {
    /// Create a new `TokenDeleteTransaction`.
    public init(
        tokenId: TokenId? = nil
    ) {
        self.tokenId = tokenId

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_TokenDeleteTransactionBody) throws {
        self.tokenId = data.hasToken ? .fromProtobuf(data.token) : nil

        try super.init(protobuf: proto)
    }

    /// The token to be deleted.
    public var tokenId: TokenId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the token to be deleted.
    @discardableResult
    public func tokenId(_ tokenId: TokenId) -> Self {
        self.tokenId = tokenId

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try tokenId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_TokenServiceAsyncClient(channel: channel).deleteToken(request)
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .tokenDeletion(toProtobuf())
    }
}

extension TokenDeleteTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_TokenDeleteTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            tokenId?.toProtobufInto(&proto.token)
        }
    }
}

extension TokenDeleteTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .tokenDeletion(toProtobuf())
    }
}
