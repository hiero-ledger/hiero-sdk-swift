// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Mint tokens to the token's treasury account.
public final class TokenMintTransaction: Transaction {
    /// Create a new `TokenMintTransaction`.
    public init(
        tokenId: TokenId? = nil,
        amount: UInt64 = 0,
        metadata: [Data] = []
    ) {
        self.tokenId = tokenId
        self.amount = amount
        self.metadata = metadata

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_TokenMintTransactionBody) throws {
        self.tokenId = data.hasToken ? .fromProtobuf(data.token) : nil
        self.amount = data.amount
        self.metadata = data.metadata

        try super.init(protobuf: proto)
    }

    /// The token for which to mint tokens.
    public var tokenId: TokenId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the token for which to mint tokens.
    @discardableResult
    public func tokenId(_ tokenId: TokenId) -> Self {
        self.tokenId = tokenId

        return self
    }

    /// The amount of a fungible token to mint to the treasury account.
    public var amount: UInt64 {
        willSet {
            ensureNotFrozen()
        }
    }

    //// Sets the amount of a fungible token to mint to the treasury account.
    @discardableResult
    public func amount(_ amount: UInt64) -> Self {
        self.amount = amount

        return self
    }

    /// The list of metadata for a non-fungible token to mint to the treasury account.
    public var metadata: [Data] {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the list of metadata for a non-fungible token to mint to the treasury account.
    @discardableResult
    public func metadata(_ metadata: [Data]) -> Self {
        self.metadata = metadata

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
        try await Proto_TokenServiceAsyncClient(channel: channel).mintToken(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .tokenMint(toProtobuf())
    }
}

extension TokenMintTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_TokenMintTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            tokenId?.toProtobufInto(&proto.token)
            proto.amount = amount
            proto.metadata = metadata
        }
    }
}

extension TokenMintTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .tokenMint(toProtobuf())
    }
}
