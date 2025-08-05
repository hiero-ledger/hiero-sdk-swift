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
                let amount: Int64 = try toInt(name: "amount", from: hbar.amount, for: method)
                tx.approveHbarAllowance(ownerAccountId, spenderAccountId, Hbar.fromTinybars(amount))

            case let (nil, token?, nil):
                let tokenId = try TokenId.fromString(token.tokenId)
                let amount: Int64 = try toInt(name: "amount", from: token.amount, for: method)
                tx.approveTokenAllowance(tokenId, ownerAccountId, spenderAccountId, toUint64(amount))

            case let (nil, nil, nft?):
                let tokenId = try TokenId.fromString(nft.tokenId)

                if let serials = nft.serialNumbers {
                    for serial in serials {
                        let serialNum = toUint64(
                            try toInt(name: "serial number in serialNumbers", from: serial, for: method))
                        let nftId = NftId(tokenId: tokenId, serial: serialNum)

                        tx.approveTokenNftAllowance(
                            nftId,
                            ownerAccountId,
                            spenderAccountId,
                            try nft.delegateSpenderAccountId.flatMap(AccountId.fromString)
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

        let txReceipt = try await tx.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `deleteAllowance` JSON-RPC method.
    internal func deleteAllowance(from params: DeleteAllowanceParams) async throws -> JSONObject {
        var tx = AccountAllowanceDeleteTransaction()
        let method: JSONRPCMethod = .deleteAllowance

        for allowance in params.allowances {
            let ownerAccountId = try AccountId.fromString(allowance.ownerAccountId)
            let tokenId = try TokenId.fromString(allowance.tokenId)

            for serialNumber in allowance.serialNumbers {
                let nftId = NftId(
                    tokenId: tokenId,
                    serial: toUint64(
                        try toInt(name: "serial number in serialNumbers list", from: serialNumber, for: method)))
                tx.deleteAllTokenNftAllowances(nftId, ownerAccountId)
            }
        }

        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        let txReceipt = try await tx.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `createAccount` JSON-RPC method.
    internal func createAccount(from params: CreateAccountParams) async throws -> JSONObject {
        var tx = AccountCreateTransaction()
        let method: JSONRPCMethod = .createAccount

        tx.key = try CommonParamsParser.getKeyIfPresent(from: params.key)
        tx.initialBalance =
            try params.initialBalance.flatMap {
                Hbar.fromTinybars(try toInt(name: "initialBalance", from: $0, for: method))
            }
            ?? tx.initialBalance
        tx.receiverSignatureRequired = params.receiverSignatureRequired ?? tx.receiverSignatureRequired
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod, for: method)
        tx.accountMemo = params.memo ?? tx.accountMemo
        tx.maxAutomaticTokenAssociations = params.maxAutoTokenAssociations ?? tx.maxAutomaticTokenAssociations
        tx.alias = try params.alias.flatMap { try EvmAddress.fromString($0) }
        tx.stakedAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.stakedAccountId)
        tx.stakedNodeId = try CommonParamsParser.getStakedNodeIdIfPresent(from: params.stakedNodeId, for: method)
        tx.declineStakingReward = params.declineStakingReward ?? tx.declineStakingReward
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        let txReceipt = try await tx.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
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

        let txReceipt = try await tx.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `transferCrypto` JSON-RPC method.
    internal func transferCrypto(from params: TransferCryptoParams) async throws -> JSONObject {
        var tx = TransferTransaction()
        let method: JSONRPCMethod = .transferCrypto

        if let transfers = params.transfers {
            for transfer in transfers {
                let approved: Bool = transfer.approved ?? false

                if let hbar = transfer.hbar {
                    let amount = Hbar.fromTinybars(try toInt(name: "amount", from: hbar.amount, for: method))

                    if let accountIdStr = hbar.accountId {
                        let accountId = try AccountId.fromString(accountIdStr)
                        approved
                            ? tx.approvedHbarTransfer(accountId, amount)
                            : tx.hbarTransfer(accountId, amount)

                    } else if let evmAddressStr = hbar.evmAddress {
                        let evmAddress = try EvmAddress.fromString("0x" + evmAddressStr)
                        let accountId = AccountId.fromEvmAddress(evmAddress)
                        approved
                            ? tx.approvedHbarTransfer(accountId, amount)
                            : tx.hbarTransfer(evmAddress, amount)
                    }

                } else if let token = transfer.token {
                    let accountId = try AccountId.fromString(token.accountId)
                    let tokenId = try TokenId.fromString(token.tokenId)
                    let amount: Int64 = try toInt(name: "amount", from: token.amount, for: method)

                    if let decimals = token.decimals {
                        approved
                            ? tx.approvedTokenTransferWithDecimals(tokenId, accountId, amount, decimals)
                            : tx.tokenTransferWithDecimals(tokenId, accountId, amount, decimals)
                    } else {
                        approved
                            ? tx.approvedTokenTransfer(tokenId, accountId, amount)
                            : tx.tokenTransfer(tokenId, accountId, amount)
                    }

                } else if let nft = transfer.nft {
                    let sender = try AccountId.fromString(nft.senderAccountId)
                    let receiver = try AccountId.fromString(nft.receiverAccountId)
                    let nftId = NftId(
                        tokenId: try TokenId.fromString(nft.tokenId),
                        serial: toUint64(try toInt(name: "serialNumber", from: nft.serialNumber, for: method)))

                    approved
                        ? tx.approvedNftTransfer(nftId, sender, receiver)
                        : tx.nftTransfer(nftId, sender, receiver)

                } else {
                    // Defensive guard: validation should prevent this, but double-check at runtime.
                    throw JSONError.invalidParams("Only one type of transfer SHALL be provided per transfer.")
                }
            }
        }

        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        let txReceipt = try await tx.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
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

        let txReceipt = try await tx.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }
}
