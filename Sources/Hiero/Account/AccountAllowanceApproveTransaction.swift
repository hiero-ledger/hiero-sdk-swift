// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Creates one or more hbar/token approved allowances **relative to the owner account specified in the allowances of
/// this transaction**.
///
/// Each allowance grants a spender the right to transfer a pre-determined amount of the owner's
/// hbar/token to any other account of the spender's choice. If the owner is not specified in any
/// allowance, the payer of transaction is considered to be the owner for that particular allowance.
///
/// Setting the amount to zero will remove the respective allowance for the spender.
///
public final class AccountAllowanceApproveTransaction: Transaction {
    private var hbarAllowances: [HbarAllowance] = [] {
        willSet {
            ensureNotFrozen(fieldName: "hbarAllowances")
        }
    }

    private var tokenAllowances: [TokenAllowance] = [] {
        willSet {
            ensureNotFrozen(fieldName: "tokenAllowances")
        }
    }

    private var nftAllowances: [TokenNftAllowance] = [] {
        willSet {
            ensureNotFrozen(fieldName: "nftAllowances")
        }
    }

    /// Create a new `AccountAllowanceApproveTransaction`.
    public override init() {
        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_CryptoApproveAllowanceTransactionBody) throws {
        hbarAllowances = try .fromProtobuf(data.cryptoAllowances)
        tokenAllowances = try .fromProtobuf(data.tokenAllowances)
        nftAllowances = try .fromProtobuf(data.nftAllowances)

        try super.init(protobuf: proto)
    }

    /// Approves the hbar allowance.
    @discardableResult
    public func approveHbarAllowance(
        _ ownerAccountId: AccountId,
        _ spenderAccountId: AccountId,
        _ amount: Hbar
    ) -> Self {
        hbarAllowances.append(
            HbarAllowance(
                ownerAccountId: ownerAccountId,
                spenderAccountId: spenderAccountId,
                amount: amount))

        return self
    }

    public func getHbarApprovals() -> [HbarAllowance] {
        self.hbarAllowances
    }

    /// Approves the token allowance.
    @discardableResult
    public func approveTokenAllowance(
        _ tokenId: TokenId,
        _ ownerAccountId: AccountId,
        _ spenderAccountId: AccountId,
        _ amount: UInt64
    ) -> Self {
        tokenAllowances.append(
            TokenAllowance(
                tokenId: tokenId,
                ownerAccountId: ownerAccountId,
                spenderAccountId: spenderAccountId,
                amount: amount))

        return self
    }

    public func getTokenApprovals() -> [TokenAllowance] {
        self.tokenAllowances
    }

    /// Approves the token NFT allowance.
    @discardableResult
    public func approveTokenNftAllowance(
        _ nftId: NftId,
        _ ownerAccountId: AccountId,
        _ spenderAccountId: AccountId,
        _ delegatingSpenderAccountId: AccountId? = nil
    ) -> Self {
        nftAllowances.append(
            TokenNftAllowance(
                tokenId: nftId.tokenId,
                ownerAccountId: ownerAccountId,
                spenderAccountId: spenderAccountId,
                serials: [nftId.serial],
                approvedForAll: nil,
                delegatingSpenderAccountId: delegatingSpenderAccountId
            ))

        return self
    }

    /// Approve the NFT allowance on all serial numbers (present and future).
    @discardableResult
    public func approveTokenNftAllowanceAllSerials(
        _ tokenId: TokenId,
        _ ownerAccountId: AccountId,
        _ spenderAccountId: AccountId
    ) -> Self {

        nftAllowances.append(
            TokenNftAllowance(
                tokenId: tokenId,
                ownerAccountId: ownerAccountId,
                spenderAccountId: spenderAccountId,
                serials: [],
                approvedForAll: true,
                delegatingSpenderAccountId: nil
            ))

        return self
    }

    /// Delete the NFT allowance on all serial numbers (present and future).
    @discardableResult
    public func deleteTokenNftAllowanceAllSerials(
        _ tokenId: TokenId,
        _ ownerAccountId: AccountId,
        _ spenderAccountId: AccountId
    ) -> Self {

        nftAllowances.append(
            TokenNftAllowance(
                tokenId: tokenId,
                ownerAccountId: ownerAccountId,
                spenderAccountId: spenderAccountId,
                serials: [],
                approvedForAll: false,
                delegatingSpenderAccountId: nil
            ))

        return self
    }

    public func getNftApprovals() -> [TokenNftAllowance] {
        self.nftAllowances
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try hbarAllowances.validateChecksums(on: ledgerId)
        try tokenAllowances.validateChecksums(on: ledgerId)
        try nftAllowances.validateChecksums(on: ledgerId)

        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_CryptoServiceAsyncClient(channel: channel).approveAllowances(
            request, callOptions: applyGrpcHeader())
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .cryptoApproveAllowance(toProtobuf())
    }
}

extension AccountAllowanceApproveTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_CryptoApproveAllowanceTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.cryptoAllowances = hbarAllowances.toProtobuf()
            proto.tokenAllowances = tokenAllowances.toProtobuf()
            proto.nftAllowances = nftAllowances.toProtobuf()
        }
    }
}

extension AccountAllowanceApproveTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .cryptoApproveAllowance(toProtobuf())
    }
}
