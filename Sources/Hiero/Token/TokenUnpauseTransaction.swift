// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Unpauses a previously paused token.
public final class TokenUnpauseTransaction: Transaction {
    /// Create a new `TokenUnpauseTransaction`.
    public init(
        tokenId: TokenId? = nil
    ) {
        self.tokenId = tokenId

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_TokenUnpauseTransactionBody) throws {
        self.tokenId = data.hasToken ? .fromProtobuf(data.token) : nil

        try super.init(protobuf: proto)
    }

    /// The token to be unpaused.
    public var tokenId: TokenId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the token to be unpaused.
    @discardableResult
    public func tokenId(_ tokenId: TokenId?) -> Self {
        self.tokenId = tokenId

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try tokenId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(
        _ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval
    ) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_TokenServiceAsyncClient(channel: channel).unpauseToken(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .tokenUnpause(toProtobuf())
    }
}

extension TokenUnpauseTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_TokenUnpauseTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            tokenId?.toProtobufInto(&proto.token)
        }
    }
}

extension TokenUnpauseTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .tokenUnpause(toProtobuf())
    }
}
