// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Service responsible for handling account-related JSON-RPC methods.
///
/// Each method corresponds to a specific JSON-RPC operation, maps input parameters into
/// Hiero SDK requests, and returns a structured result.
internal enum AccountService {

    // MARK: - JSON-RPC Methods

    /// Handles the `approveAllowance` JSON-RPC method.
    internal static func approveAllowance(from params: ApproveAllowanceParams) async throws -> JSONObject {
        var tx = AccountAllowanceApproveTransaction()
        let method: JSONRPCMethod = .approveAllowance

        for allowance in params.allowances {
            let ownerAccountId = try AccountId.fromString(allowance.ownerAccountId)
            let spenderAccountId = try AccountId.fromString(allowance.spenderAccountId)

            switch (allowance.hbar, allowance.token, allowance.nft) {
            case (let hbar?, nil, nil):
                let amount = try CommonParamsParser.getAmount(
                    from: hbar.amount,
                    for: method,
                    using: JSONRPCParam.parseInt64(name:from:for:))
                tx.approveHbarAllowance(ownerAccountId, spenderAccountId, Hbar.fromTinybars(amount))

            case (nil, let token?, nil):
                let tokenId = try TokenId.fromString(token.tokenId)
                let amount = try CommonParamsParser.getAmount(
                    from: token.amount,
                    for: method,
                    using: JSONRPCParam.parseUInt64ReinterpretingSigned(name:from:for:))
                tx.approveTokenAllowance(tokenId, ownerAccountId, spenderAccountId, amount)

            case (nil, nil, let nft?):
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

        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `deleteAllowance` JSON-RPC method.
    internal static func deleteAllowance(from params: DeleteAllowanceParams) async throws -> JSONObject {
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

        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `createAccount` JSON-RPC method.
    internal static func createAccount(from params: CreateAccountParams) async throws -> JSONObject {
        var tx = AccountCreateTransaction()
        let method: JSONRPCMethod = .createAccount

        tx.key = try CommonParamsParser.getKeyIfPresent(from: params.key)
        try params.initialBalance.assign(to: &tx.initialBalance) {
            Hbar.fromTinybars(try JSONRPCParam.parseInt64(name: "initialBalance", from: $0, for: method))
        }
        params.receiverSignatureRequired.assign(to: &tx.receiverSignatureRequired)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod,
            for: method)
        params.memo.assign(to: &tx.accountMemo)
        params.maxAutoTokenAssociations.assign(to: &tx.maxAutomaticTokenAssociations)
        try params.alias.flatMap { try EvmAddress.fromString($0) }.assign(to: &tx.alias)
        tx.stakedAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.stakedAccountId)
        tx.stakedNodeId = try CommonParamsParser.getStakedNodeIdIfPresent(from: params.stakedNodeId, for: method)
        params.declineStakingReward.assign(to: &tx.declineStakingReward)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary([
            "accountId": .string(txReceipt.accountId!.toString()),
            "status": .string(txReceipt.status.description),
        ])
    }

    /// Handles the `deleteAccount` JSON-RPC method.
    internal static func deleteAccount(from params: DeleteAccountParams) async throws -> JSONObject {
        var tx = AccountDeleteTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.deleteAccountId)
        tx.transferAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.transferAccountId)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `transferCrypto` JSON-RPC method.
    internal static func transferCrypto(from params: TransferCryptoParams) async throws -> JSONObject {
        var tx = TransferTransaction()
        let method: JSONRPCMethod = .transferCrypto

        if let transfers = params.transfers {
            for transfer in transfers {
                let approved: Bool = transfer.approved ?? false

                if let hbar = transfer.hbar {
                    let amount = Hbar.fromTinybars(
                        try CommonParamsParser.getAmount(
                            from: hbar.amount,
                            for: method,
                            using: JSONRPCParam.parseInt64(name:from:for:)))

                    if let accountIdStr = hbar.accountId {
                        let accountId = try AccountId.fromString(accountIdStr)
                        _ = approved ? tx.approvedHbarTransfer(accountId, amount) : tx.hbarTransfer(accountId, amount)
                    } else if let evmAddressStr = hbar.evmAddress {
                        let evmAddress = try EvmAddress.fromString("0x" + evmAddressStr)
                        let accountId = try AccountId.fromEvmAddress(evmAddress, shard: 0, realm: 0)
                        _ = approved ? tx.approvedHbarTransfer(accountId, amount) : tx.hbarTransfer(evmAddress, amount)
                    }
                } else if let token = transfer.token {
                    try token.applyToTransaction(&tx, approved: approved, for: method)
                } else if let nft = transfer.nft {
                    try nft.applyToTransaction(&tx, approved: approved, for: method)
                } else {
                    // Defensive guard: validation should prevent this, but double-check at runtime.
                    throw JSONError.invalidParams("Only one type of transfer SHALL be provided per transfer.")
                }
            }
        }

        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `updateAccount` JSON-RPC method.
    internal static func updateAccount(from params: UpdateAccountParams) async throws -> JSONObject {
        var tx = AccountUpdateTransaction()
        let method: JSONRPCMethod = .updateAccount

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tx.key = try CommonParamsParser.getKeyIfPresent(from: params.key)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod,
            for: method)
        tx.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(from: params.expirationTime, for: method)
        tx.receiverSignatureRequired = params.receiverSignatureRequired
        tx.accountMemo = params.memo
        tx.maxAutomaticTokenAssociations = params.maxAutoTokenAssociations
        tx.stakedAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.stakedAccountId)
        tx.stakedNodeId = try CommonParamsParser.getStakedNodeIdIfPresent(from: params.stakedNodeId, for: method)
        tx.declineStakingReward = params.declineStakingReward
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }
}
