// SPDX-License-Identifier: Apache-2.0

import Foundation

@testable import Hiero

/// Service responsible for handling token-related JSON-RPC methods.
///
/// Each method corresponds to a specific JSON-RPC operation, maps input parameters into
/// Hiero SDK requests, and returns a structured result.
internal enum TokenService {

    // MARK: - JSON-RPC Methods

    /// Handles the `airdropToken` JSON-RPC method.
    internal static func airdropToken(from params: AirdropTokenParams) async throws -> JSONObject {
        var tx = TokenAirdropTransaction()
        let method: JSONRPCMethod = .airdropToken

        if let transfers = params.tokenTransfers {
            for transfer in transfers {
                let approved: Bool = transfer.approved ?? false

                if transfer.hbar != nil {
                    // Hbar transfers are not allowed for token airdrop.
                    throw JSONError.invalidParams("Hbar transfers SHALL NOT be provided in a token airdrop.")
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

    /// Handles the `associateToken` JSON-RPC method.
    internal static func associateToken(from params: AssociateTokenParams) async throws -> JSONObject {
        var tx = TokenAssociateTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds).assign(to: &tx.tokenIds)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `burnToken` JSON-RPC method.
    internal static func burnToken(from params: BurnTokenParams) async throws -> JSONObject {
        var tx = TokenBurnTransaction()
        let method: JSONRPCMethod = .burnToken

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try CommonParamsParser.getAmountIfPresent(from: params.amount, for: method).assign(to: &tx.amount)
        try params.serialNumbers.assign(to: &tx.serials) { serials in
            try serials.enumerated().map { index, serial in
                try CommonParamsParser.getSerialNumber(from: serial, for: method, index: index)
            }
        }
        try params.commonTransactionParams?.applyToTransaction(&tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary([
            "status": .string(txReceipt.status.description),
            "newTotalSupply": .string(String(txReceipt.totalSupply)),
        ])
    }

    /// Handles the `cancelAirdrop` JSON-RPC method.
    internal static func cancelAirdrop(from params: CancelAirdropParams) async throws -> JSONObject {
        var tx = TokenCancelAirdropTransaction()

        let airdrops = try CommonParamsParser.pendingAirdropsToHieroPendingAirdropIds(
            params.pendingAirdrops,
            for: .cancelAirdrop)
        for airdrop in airdrops {
            tx.addPendingAirdropId(airdrop)
        }

        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `claimToken` JSON-RPC method.
    internal static func claimToken(from params: ClaimTokenParams) async throws -> JSONObject {
        var tx = TokenClaimAirdropTransaction()

        let senderAccountId = try AccountId.fromString(params.senderAccountId)
        let receiverAccountId = try AccountId.fromString(params.receiverAccountId)
        let tokenId = try TokenId.fromString(params.tokenId)

        if let serialNumbers = params.serialNumbers {
            for serial in serialNumbers {
                tx.addPendingAirdropId(
                    PendingAirdropId(
                        senderId: senderAccountId,
                        receiverId: receiverAccountId,
                        nftId: NftId(
                            tokenId: tokenId,
                            serial: try CommonParamsParser.getSerialNumber(from: serial, for: JSONRPCMethod.claimToken))
                    ))
            }
        } else {
            tx.addPendingAirdropId(
                PendingAirdropId(senderId: senderAccountId, receiverId: receiverAccountId, tokenId: tokenId))
        }

        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `createToken` JSON-RPC method.
    internal static func createToken(from params: CreateTokenParams) async throws -> JSONObject {
        var tx = TokenCreateTransaction()
        let method: JSONRPCMethod = .createToken

        params.name.assign(to: &tx.name)
        params.symbol.assign(to: &tx.symbol)
        params.decimals.assign(to: &tx.decimals)
        try JSONRPCParam.parseUInt64IfPresentReinterpretingSigned(
            name: "initialSupply",
            from: params.initialSupply,
            for: method
        ).assign(to: &tx.initialSupply)
        tx.treasuryAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.treasuryAccountId)
        tx.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        tx.kycKey = try CommonParamsParser.getKeyIfPresent(from: params.kycKey)
        tx.freezeKey = try CommonParamsParser.getKeyIfPresent(from: params.freezeKey)
        tx.wipeKey = try CommonParamsParser.getKeyIfPresent(from: params.wipeKey)
        tx.supplyKey = try CommonParamsParser.getKeyIfPresent(from: params.supplyKey)
        params.freezeDefault.assign(to: &tx.freezeDefault)
        tx.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(from: params.expirationTime, for: method)
        tx.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.autoRenewAccountId)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod,
            for: method)
        params.memo.assign(to: &tx.tokenMemo)
        try params.tokenType.flatMap {
            try ["ft", "nft"].contains($0)
                ? ($0 == "ft" ? .fungibleCommon : .nonFungibleUnique)
                : { throw JSONError.invalidParams("\(#function): tokenType MUST be 'ft' or 'nft'.") }()
        }.assign(to: &tx.tokenType)
        try params.supplyType.flatMap {
            try ["finite", "infinite"].contains($0)
                ? ($0 == "finite" ? .finite : .infinite)
                : { throw JSONError.invalidParams("\(#function): supplyType MUST be 'finite' or 'infinite'.") }()
        }.assign(to: &tx.tokenSupplyType)
        try JSONRPCParam.parseUInt64IfPresentReinterpretingSigned(
            name: "maxSupply",
            from: params.maxSupply,
            for: method
        ).assign(to: &tx.maxSupply)
        tx.feeScheduleKey = try CommonParamsParser.getKeyIfPresent(from: params.feeScheduleKey)
        try CommonParamsParser.getHieroAnyCustomFeesIfPresent(from: params.customFees, for: method).assign(
            to: &tx.customFees)
        tx.pauseKey = try CommonParamsParser.getKeyIfPresent(from: params.pauseKey)
        try CommonParamsParser.getMetadataIfPresent(from: params.metadata, for: method).assign(to: &tx.metadata)
        tx.metadataKey = try CommonParamsParser.getKeyIfPresent(from: params.metadataKey)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary([
            "tokenId": .string(txReceipt.tokenId!.toString()),
            "status": .string(txReceipt.status.description),
        ])
    }

    /// Handles the `deleteToken` JSON-RPC method.
    internal static func deleteToken(from params: DeleteTokenParams) async throws -> JSONObject {
        var tx = TokenDeleteTransaction()

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `dissociateToken` JSON-RPC method.
    internal static func dissociateToken(from params: DissociateTokenParams) async throws -> JSONObject {
        var tx = TokenDissociateTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds).assign(to: &tx.tokenIds)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `freezeToken` JSON-RPC method.
    internal static func freezeToken(from params: FreezeTokenParams) async throws -> JSONObject {
        var tx = TokenFreezeTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `grantTokenKyc` JSON-RPC method.
    internal static func grantTokenKyc(from params: GrantTokenKycParams) async throws -> JSONObject {
        var tx = TokenGrantKycTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `mintToken` JSON-RPC method.
    internal static func mintToken(from params: MintTokenParams) async throws -> JSONObject {
        var tx = TokenMintTransaction()
        let method: JSONRPCMethod = .mintToken

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try CommonParamsParser.getAmountIfPresent(from: params.amount, for: method).assign(to: &tx.amount)
        try params.metadata.assign(to: &tx.metadata) { metadata in
            try metadata.enumerated().map { idx, param in
                try JSONRPCParam.parseUtf8Data(name: "metadata[\(idx)]", from: param, for: method)
            }
        }
        try params.commonTransactionParams?.applyToTransaction(&tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary(
            [
                "status": .string(txReceipt.status.description),
                "newTotalSupply": .string(String(txReceipt.totalSupply)),
            ].merging(
                txReceipt.serials.map { ["serialNumbers": .list($0.map { .string(String($0)) })] }
                    ?? [:]
            ) { _, new in new })

    }

    /// Handles the `pauseToken` JSON-RPC method.
    internal static func pauseToken(from params: PauseTokenParams) async throws -> JSONObject {
        var tx = TokenPauseTransaction()

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `rejectToken` JSON-RPC method.
    internal static func rejectToken(from params: RejectTokenParams) async throws -> JSONObject {
        var tx = TokenRejectTransaction()

        tx.owner = try AccountId.fromString(params.ownerId)

        if let serials = params.serialNumbers {
            var tokenIds = [TokenId]()
            try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds).assign(to: &tokenIds)

            for (index, serial) in serials.enumerated() {
                let nftId = NftId(
                    tokenId: tokenIds[0],
                    serial: try CommonParamsParser.getSerialNumber(from: serial, for: .rejectToken, index: index))
                tx.addNftId(nftId)
            }
        } else {
            try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds).assign(to: &tx.tokenIds)
        }
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `revokeTokenKyc` JSON-RPC method.
    internal static func revokeTokenKyc(from params: RevokeTokenKycParams) async throws -> JSONObject {
        var tx = TokenRevokeKycTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `unfreezeToken` JSON-RPC method.
    internal static func unfreezeToken(from params: UnfreezeTokenParams) async throws -> JSONObject {
        var tx = TokenUnfreezeTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `unpauseToken` JSON-RPC method.
    internal static func unpauseToken(from params: UnpauseTokenParams) async throws -> JSONObject {
        var tx = TokenUnpauseTransaction()

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `updateTokenFeeSchedule` JSON-RPC method.
    internal static func updateTokenFeeSchedule(from params: UpdateTokenFeeScheduleParams) async throws -> JSONObject {
        var tx = TokenFeeScheduleUpdateTransaction()

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try CommonParamsParser.getHieroAnyCustomFeesIfPresent(
            from: params.customFees,
            for: JSONRPCMethod.updateTokenFeeSchedule
        ).assign(to: &tx.customFees)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `updateToken` JSON-RPC method.
    internal static func updateToken(from params: UpdateTokenParams) async throws -> JSONObject {
        var tx = TokenUpdateTransaction()
        let method: JSONRPCMethod = .updateToken

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        params.name.assign(to: &tx.tokenName)
        params.symbol.assign(to: &tx.tokenSymbol)
        tx.treasuryAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.treasuryAccountId)
        tx.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        tx.kycKey = try CommonParamsParser.getKeyIfPresent(from: params.kycKey)
        tx.freezeKey = try CommonParamsParser.getKeyIfPresent(from: params.freezeKey)
        tx.wipeKey = try CommonParamsParser.getKeyIfPresent(from: params.wipeKey)
        tx.supplyKey = try CommonParamsParser.getKeyIfPresent(from: params.supplyKey)
        tx.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.autoRenewAccountId)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod,
            for: method)
        tx.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(from: params.expirationTime, for: method)
        tx.tokenMemo = params.memo
        tx.feeScheduleKey = try CommonParamsParser.getKeyIfPresent(from: params.feeScheduleKey)
        tx.pauseKey = try CommonParamsParser.getKeyIfPresent(from: params.pauseKey)
        tx.metadata = try CommonParamsParser.getMetadataIfPresent(from: params.metadata, for: method)
        tx.metadataKey = try CommonParamsParser.getKeyIfPresent(from: params.metadataKey)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }
}
