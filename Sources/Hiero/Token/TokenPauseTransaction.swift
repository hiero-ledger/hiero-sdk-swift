// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Pauses the token from being involved in any kind of transaction until it is unpaused.
public final class TokenPauseTransaction: Transaction {
    /// Create a new `TokenPauseTransaction`.
    public init(
        tokenId: TokenId? = nil
    ) {
        self.tokenId = tokenId

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_TokenPauseTransactionBody) throws {
        self.tokenId = data.hasToken ? .fromProtobuf(data.token) : nil

        try super.init(protobuf: proto)
    }

    /// The token to be paused.
    public var tokenId: TokenId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the token to be paused.
    @discardableResult
    public func tokenId(_ tokenId: TokenId?) -> Self {
        self.tokenId = tokenId

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try tokenId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_TokenServiceAsyncClient(channel: channel).pauseToken(request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .tokenPause(toProtobuf())
    }
}

extension TokenPauseTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_TokenPauseTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            tokenId?.toProtobufInto(&proto.token)
        }
    }
}

extension TokenPauseTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .tokenPause(toProtobuf())
    }
}
