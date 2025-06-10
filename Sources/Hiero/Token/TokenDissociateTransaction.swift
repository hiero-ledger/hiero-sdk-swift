// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Dissociates the provided account with the provided tokens.
///
/// Must be signed by the provided account's key.
///
public final class TokenDissociateTransaction: Transaction {
    /// Create a new `TokenDissociateTransaction`.
    public init(
        accountId: AccountId? = nil,
        tokenIds: [TokenId] = []
    ) {
        self.accountId = accountId
        self.tokenIds = tokenIds

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_TokenDissociateTransactionBody) throws {
        self.tokenIds = .fromProtobuf(data.tokens)
        self.accountId = data.hasAccount ? try .fromProtobuf(data.account) : nil

        try super.init(protobuf: proto)
    }

    /// The account to be dissociated with the provided tokens.
    public var accountId: AccountId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the account to be dissociated with the provided tokens.
    @discardableResult
    public func accountId(_ accountId: AccountId?) -> Self {
        self.accountId = accountId

        return self
    }

    /// The tokens to be dissociated with the provided account.
    public var tokenIds: [TokenId] {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the tokens to be dissociated with the provided account.
    @discardableResult
    public func tokenIds(_ tokenIds: [TokenId]) -> Self {
        self.tokenIds = tokenIds

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try accountId?.validateChecksums(on: ledgerId)
        try tokenIds.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_TokenServiceAsyncClient(channel: channel).dissociateTokens(
            request, callOptions: applyGrpcHeader())
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .tokenDissociate(toProtobuf())
    }
}

extension TokenDissociateTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_TokenDissociateTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.tokens = tokenIds.toProtobuf()
            accountId?.toProtobufInto(&proto.account)
        }
    }
}

extension TokenDissociateTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .tokenDissociate(toProtobuf())
    }
}
