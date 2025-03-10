// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Revokes KYC from the account for the given token.
public final class TokenRevokeKycTransaction: Transaction {
    /// Create a new `TokenRevokeKycTransaction`.
    public init(
        accountId: AccountId? = nil,
        tokenId: TokenId? = nil
    ) {
        self.accountId = accountId
        self.tokenId = tokenId

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_TokenRevokeKycTransactionBody) throws {
        self.tokenId = data.hasToken ? .fromProtobuf(data.token) : nil
        self.accountId = data.hasAccount ? try .fromProtobuf(data.account) : nil

        try super.init(protobuf: proto)
    }

    /// The account to have their KYC revoked.
    public var accountId: AccountId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the account to have their KYC revoked.
    @discardableResult
    public func accountId(_ accountId: AccountId?) -> Self {
        self.accountId = accountId

        return self
    }

    /// The token for which this account will have their KYC revoked.
    public var tokenId: TokenId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the token for which this account will have their KYC revoked.
    @discardableResult
    public func tokenId(_ tokenId: TokenId) -> Self {
        self.tokenId = tokenId

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try accountId?.validateChecksums(on: ledgerId)
        try tokenId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_TokenServiceAsyncClient(channel: channel).revokeKycFromTokenAccount(request)
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .tokenRevokeKyc(toProtobuf())
    }
}

extension TokenRevokeKycTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_TokenRevokeKycTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            tokenId?.toProtobufInto(&proto.token)
            accountId?.toProtobufInto(&proto.account)
        }
    }
}

extension TokenRevokeKycTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .tokenRevokeKyc(toProtobuf())
    }
}
