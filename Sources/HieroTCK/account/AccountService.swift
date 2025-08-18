// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Service responsible for handling account-related JSON-RPC methods.
///
/// Each method corresponds to a specific JSON-RPC operation, maps input parameters into
/// Hiero SDK requests, and returns a structured result.
internal class AccountService {

    // MARK: - Singleton

    /// Singleton instance of AccountService.
    static let service = AccountService()
    fileprivate init() {}

    // MARK: - JSON-RPC Methods

    /// Handles the `approveAllowance` JSON-RPC method.
    internal func approveAllowance(from params: ApproveAllowanceParams) async throws -> JSONObject {
        var tx = AccountAllowanceApproveTransaction()
        let method: JSONRPCMethod = .approveAllowance

        for allowance in params.allowances {
            let ownerAccountId = try AccountId.fromString(allowance.ownerAccountId)
            let spenderAccountId = try AccountId.fromString(allowance.spenderAccountId)

            switch (allowance.hbar, allowance.token, allowance.nft) {
            case let (hbar?, nil, nil):
                let amount = try CommonParamsParser.getAmount(
                    from: hbar.amount, for: method, using: parseInt64(name:from:for:))
                tx.approveHbarAllowance(ownerAccountId, spenderAccountId, Hbar.fromTinybars(amount))

            case let (nil, token?, nil):
                let tokenId = try TokenId.fromString(token.tokenId)
                let amount = try CommonParamsParser.getAmount(
                    from: token.amount, for: method, using: parseUInt64ReinterpretingSigned(name:from:for:))
                tx.approveTokenAllowance(tokenId, ownerAccountId, spenderAccountId, amount)

            case let (nil, nil, nft?):
                let tokenId = try TokenId.fromString(nft.tokenId)

                if let serials = nft.serialNumbers {
                    for (index, serial) in serials.enumerated() {
                        let nftId = NftId(
                            tokenId: tokenId,
                            serial: try CommonParamsParser.getSerialNumber(from: serial, for: method, index: index))

                        tx.approveTokenNftAllowance(
                            nftId,
                            ownerAccountId,
                            spenderAccountId,
                            try nft.delegateSpenderAccountId.map(AccountId.fromString)
                        )
                    }
                } else if let approvedForAll = nft.approvedForAll, approvedForAll {
                    tx.approveTokenNftAllowanceAllSerials(tokenId, ownerAccountId, spenderAccountId)
                } else {
                    tx.deleteTokenNftAllowanceAllSerials(tokenId, ownerAccountId, spenderAccountId)
                }

            default:
                // Defensive guard: validation should prevent this, but double-check at runtime.
                throw JSONError.invalidParams("Only one type of allowance SHALL be provided per allowance.")
            }
        }

        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `deleteAllowance` JSON-RPC method.
    internal func deleteAllowance(from params: DeleteAllowanceParams) async throws -> JSONObject {
        var tx = AccountAllowanceDeleteTransaction()
        let method: JSONRPCMethod = .deleteAllowance

        for allowance in params.allowances {
            let ownerAccountId = try AccountId.fromString(allowance.ownerAccountId)
            let tokenId = try TokenId.fromString(allowance.tokenId)

            for (index, serial) in allowance.serialNumbers.enumerated() {
                let nftId = NftId(
                    tokenId: tokenId,
                    serial: try CommonParamsParser.getSerialNumber(from: serial, for: method, index: index))
                tx.deleteAllTokenNftAllowances(nftId, ownerAccountId)
            }
        }

        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `createAccount` JSON-RPC method.
    internal func createAccount(from params: CreateAccountParams) async throws -> JSONObject {
        var tx = AccountCreateTransaction()
        let method: JSONRPCMethod = .createAccount

        tx.key = try CommonParamsParser.getKeyIfPresent(from: params.key)
        setIfPresent(
            &tx.initialBalance,
            to: try params.initialBalance.flatMap {
                Hbar.fromTinybars(try parseInt64(name: "initialBalance", from: $0, for: method))
            })
        setIfPresent(&tx.receiverSignatureRequired, to: params.receiverSignatureRequired)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod, for: method)
        setIfPresent(&tx.accountMemo, to: params.memo)
        setIfPresent(&tx.maxAutomaticTokenAssociations, to: params.maxAutoTokenAssociations)
        tx.alias = try params.alias.flatMap { try EvmAddress.fromString($0) }
        tx.stakedAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.stakedAccountId)
        tx.stakedNodeId = try CommonParamsParser.getStakedNodeIdIfPresent(from: params.stakedNodeId, for: method)
        setIfPresent(&tx.declineStakingReward, to: params.declineStakingReward)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary([
            "accountId": .string(txReceipt.accountId!.toString()),
            "status": .string(txReceipt.status.description),
        ])
    }

    /// Handles the `deleteAccount` JSON-RPC method.
    internal func deleteAccount(from params: DeleteAccountParams) async throws -> JSONObject {
        var tx = AccountDeleteTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.deleteAccountId)
        tx.transferAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.transferAccountId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `transferCrypto` JSON-RPC method.
    internal func transferCrypto(from params: TransferCryptoParams) async throws -> JSONObject {
        var tx = TransferTransaction()
        let method: JSONRPCMethod = .transferCrypto

        if let transfers = params.transfers {
            for transfer in transfers {
                let approved: Bool = transfer.approved ?? false

                if let hbar = transfer.hbar {
                    let amount = Hbar.fromTinybars(
                        try CommonParamsParser.getAmount(
                            from: hbar.amount, for: method, using: parseInt64(name:from:for:)))

                    if let accountIdStr = hbar.accountId {
                        let accountId = try AccountId.fromString(accountIdStr)
                        _ = approved ? tx.approvedHbarTransfer(accountId, amount) : tx.hbarTransfer(accountId, amount)
                    } else if let evmAddressStr = hbar.evmAddress {
                        let evmAddress = try EvmAddress.fromString("0x" + evmAddressStr)
                        let accountId = try AccountId.fromEvmAddress(evmAddress, shard: 0, realm: 0)
                        _ = approved ? tx.approvedHbarTransfer(accountId, amount) : tx.hbarTransfer(evmAddress, amount)
                    }
                } else if let token = transfer.token {
                    let accountId = try AccountId.fromString(token.accountId)
                    let tokenId = try TokenId.fromString(token.tokenId)
                    let amount = try CommonParamsParser.getAmount(
                        from: token.amount, for: method, using: parseInt64(name:from:for:))

                    if let decimals = token.decimals {
                        _ =
                            approved
                            ? tx.approvedTokenTransferWithDecimals(tokenId, accountId, amount, decimals)
                            : tx.tokenTransferWithDecimals(tokenId, accountId, amount, decimals)
                    } else {
                        _ =
                            approved
                            ? tx.approvedTokenTransfer(tokenId, accountId, amount)
                            : tx.tokenTransfer(tokenId, accountId, amount)
                    }
                } else if let nft = transfer.nft {
                    let sender = try AccountId.fromString(nft.senderAccountId)
                    let receiver = try AccountId.fromString(nft.receiverAccountId)
                    let nftId = NftId(
                        tokenId: try TokenId.fromString(nft.tokenId),
                        serial: try CommonParamsParser.getSerialNumber(from: nft.serialNumber, for: method))
                    _ =
                        approved
                        ? tx.approvedNftTransfer(nftId, sender, receiver) : tx.nftTransfer(nftId, sender, receiver)
                } else {
                    // Defensive guard: validation should prevent this, but double-check at runtime.
                    throw JSONError.invalidParams("Only one type of transfer SHALL be provided per transfer.")
                }
            }
        }

        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `updateAccount` JSON-RPC method.
    internal func updateAccount(from params: UpdateAccountParams) async throws -> JSONObject {
        var tx = AccountUpdateTransaction()
        let method: JSONRPCMethod = .updateAccount

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tx.key = try CommonParamsParser.getKeyIfPresent(from: params.key)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod, for: method)
        tx.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(from: params.expirationTime, for: method)
        tx.receiverSignatureRequired = params.receiverSignatureRequired
        tx.accountMemo = params.memo
        tx.maxAutomaticTokenAssociations = params.maxAutoTokenAssociations
        tx.stakedAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.stakedAccountId)
        tx.stakedNodeId = try CommonParamsParser.getStakedNodeIdIfPresent(from: params.stakedNodeId, for: method)
        tx.declineStakingReward = params.declineStakingReward
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }
}
