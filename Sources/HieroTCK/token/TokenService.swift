// SPDX-License-Identifier: Apache-2.0

import Foundation

@testable import Hiero

/// Service responsible for handling token-related JSON-RPC methods.
///
/// Each method corresponds to a specific JSON-RPC operation, maps input parameters into
/// Hiero SDK requests, and returns a structured result.
internal class TokenService {

    // MARK: - Singleton

    /// Singleton instance of TokenService.
    static let service = TokenService()
    fileprivate init() {}

    // MARK: - JSON-RPC Methods

    /// Handles the `associateToken` JSON-RPC method.
    internal func associateToken(from params: AssociateTokenParams) async throws -> JSONObject {
        var tokenAssociateTransaction = TokenAssociateTransaction()

        tokenAssociateTransaction.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tokenAssociateTransaction.tokenIds =
            try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds) ?? tokenAssociateTransaction.tokenIds
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenAssociateTransaction)

        let txReceipt = try await tokenAssociateTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `burnToken` JSON-RPC method.
    internal func burnToken(from params: BurnTokenParams) async throws -> JSONObject {
        var tokenBurnTransaction = TokenBurnTransaction()
        let method: JSONRPCMethod = .burnToken

        tokenBurnTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        tokenBurnTransaction.amount =
            try CommonParamsParser.getAmountIfPresent(from: params.amount, for: method) ?? tokenBurnTransaction.amount
        tokenBurnTransaction.serials =
            try params.serialNumbers?.map {
                toUint64(try toInt(name: "serial number in serialNumbers list", from: $0, for: method))
            } ?? tokenBurnTransaction.serials
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenBurnTransaction)

        let txReceipt = try await tokenBurnTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary([
            "status": .string(txReceipt.status.description),
            "newTotalSupply": .string(String(txReceipt.totalSupply)),
        ])
    }

    /// Handles the `createToken` JSON-RPC method.
    internal func createToken(from params: CreateTokenParams) async throws -> JSONObject {
        var tokenCreateTransaction = TokenCreateTransaction()
        let method: JSONRPCMethod = .createToken

        tokenCreateTransaction.name = params.name ?? tokenCreateTransaction.name
        tokenCreateTransaction.symbol = params.symbol ?? tokenCreateTransaction.symbol
        tokenCreateTransaction.decimals = params.decimals ?? tokenCreateTransaction.decimals
        tokenCreateTransaction.initialSupply =
            try CommonParamsParser.getSdkUInt64IfPresent(name: "initialSupply", from: params.initialSupply, for: method)
            ?? tokenCreateTransaction.initialSupply
        tokenCreateTransaction.treasuryAccountId = try CommonParamsParser.getAccountIdIfPresent(
            from: params.treasuryAccountId)
        tokenCreateTransaction.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        tokenCreateTransaction.kycKey = try CommonParamsParser.getKeyIfPresent(from: params.kycKey)
        tokenCreateTransaction.freezeKey = try CommonParamsParser.getKeyIfPresent(from: params.freezeKey)
        tokenCreateTransaction.wipeKey = try CommonParamsParser.getKeyIfPresent(from: params.wipeKey)
        tokenCreateTransaction.supplyKey = try CommonParamsParser.getKeyIfPresent(from: params.supplyKey)
        tokenCreateTransaction.freezeDefault = params.freezeDefault ?? tokenCreateTransaction.freezeDefault
        tokenCreateTransaction.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(
            from: params.expirationTime, for: method)
        tokenCreateTransaction.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(
            from: params.autoRenewAccountId)
        tokenCreateTransaction.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod, for: method)
        tokenCreateTransaction.tokenMemo = params.memo ?? tokenCreateTransaction.tokenMemo
        tokenCreateTransaction.tokenType =
            try params.tokenType.flatMap {
                try ["ft", "nft"].contains($0)
                    ? ($0 == "ft" ? .fungibleCommon : .nonFungibleUnique)
                    : { throw JSONError.invalidParams("\(#function): tokenType MUST be 'ft' or 'nft'.") }()
            } ?? tokenCreateTransaction.tokenType
        tokenCreateTransaction.tokenSupplyType =
            try params.supplyType.flatMap {
                try ["finite", "infinite"].contains($0)
                    ? ($0 == "finite" ? .finite : .infinite)
                    : { throw JSONError.invalidParams("\(#function): supplyType MUST be 'finite' or 'infinite'.") }()
            } ?? tokenCreateTransaction.tokenSupplyType
        tokenCreateTransaction.maxSupply =
            try CommonParamsParser.getSdkUInt64IfPresent(name: "maxSupply", from: params.maxSupply, for: method)
            ?? tokenCreateTransaction.maxSupply
        tokenCreateTransaction.feeScheduleKey = try CommonParamsParser.getKeyIfPresent(from: params.feeScheduleKey)
        tokenCreateTransaction.customFees =
            try CommonParamsParser.getCustomFeesIfPresent(from: params.customFees, for: method)
            ?? tokenCreateTransaction.customFees
        tokenCreateTransaction.pauseKey = try CommonParamsParser.getKeyIfPresent(from: params.pauseKey)
        tokenCreateTransaction.metadata =
            try params.metadata.flatMap {
                try $0.data(using: .utf8)
                    ?? { throw JSONError.invalidParams("\(#function): metadata MUST be a UTF-8 string.") }()
            } ?? tokenCreateTransaction.metadata
        tokenCreateTransaction.metadataKey = try CommonParamsParser.getKeyIfPresent(from: params.metadataKey)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenCreateTransaction)

        let txReceipt = try await tokenCreateTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary([
            "tokenId": .string(txReceipt.tokenId!.toString()),
            "status": .string(txReceipt.status.description),
        ])
    }

    /// Handles the `deleteToken` JSON-RPC method.
    internal func deleteToken(from params: DeleteTokenParams) async throws -> JSONObject {
        var tokenDeleteTransaction = TokenDeleteTransaction()

        tokenDeleteTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenDeleteTransaction)

        let txReceipt = try await tokenDeleteTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `dissociateToken` JSON-RPC method.
    internal func dissociateToken(from params: DissociateTokenParams) async throws -> JSONObject {
        var tokenDissociateTransaction = TokenDissociateTransaction()

        tokenDissociateTransaction.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tokenDissociateTransaction.tokenIds =
            try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds) ?? tokenDissociateTransaction.tokenIds
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenDissociateTransaction)

        let txReceipt = try await tokenDissociateTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `freezeToken` JSON-RPC method.
    internal func freezeToken(from params: FreezeTokenParams) async throws -> JSONObject {
        var tokenFreezeTransaction = TokenFreezeTransaction()

        tokenFreezeTransaction.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tokenFreezeTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenFreezeTransaction)

        let txReceipt = try await tokenFreezeTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `grantTokenKyc` JSON-RPC method.
    internal func grantTokenKyc(from params: GrantTokenKycParams) async throws -> JSONObject {
        var tokenGrantKycTransaction = TokenGrantKycTransaction()

        tokenGrantKycTransaction.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tokenGrantKycTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenGrantKycTransaction)

        let txReceipt = try await tokenGrantKycTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `mintToken` JSON-RPC method.
    internal func mintToken(from params: MintTokenParams) async throws -> JSONObject {
        var tokenMintTransaction = TokenMintTransaction()

        tokenMintTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        tokenMintTransaction.amount =
            try CommonParamsParser.getAmountIfPresent(from: params.amount, for: JSONRPCMethod.mintToken)
            ?? tokenMintTransaction.amount
        tokenMintTransaction.metadata =
            try params.metadata?.map {
                try Data(hexEncoded: $0)
                    ?? { throw JSONError.invalidParams("\(#function): metadata MUST be a hex-encoded string.") }()
            } ?? tokenMintTransaction.metadata
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenMintTransaction)

        let txReceipt = try await tokenMintTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
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
    internal func pauseToken(from params: PauseTokenParams) async throws -> JSONObject {
        var tokenPauseTransaction = TokenPauseTransaction()

        tokenPauseTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenPauseTransaction)

        let txReceipt = try await tokenPauseTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `revokeTokenKyc` JSON-RPC method.
    internal func revokeTokenKyc(from params: RevokeTokenKycParams) async throws -> JSONObject {
        var tokenRevokeKycTransaction = TokenRevokeKycTransaction()

        tokenRevokeKycTransaction.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tokenRevokeKycTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenRevokeKycTransaction)

        let txReceipt = try await tokenRevokeKycTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `unfreezeToken` JSON-RPC method.
    internal func unfreezeToken(from params: UnfreezeTokenParams) async throws -> JSONObject {
        var tokenUnfreezeTransaction = TokenUnfreezeTransaction()

        tokenUnfreezeTransaction.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tokenUnfreezeTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenUnfreezeTransaction)

        let txReceipt = try await tokenUnfreezeTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `unpauseToken` JSON-RPC method.
    internal func unpauseToken(from params: UnpauseTokenParams) async throws -> JSONObject {
        var tokenUnpauseTransaction = TokenUnpauseTransaction()

        tokenUnpauseTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenUnpauseTransaction)

        let txReceipt = try await tokenUnpauseTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `updateTokenFeeSchedule` JSON-RPC method.
    internal func updateTokenFeeSchedule(from params: UpdateTokenFeeScheduleParams) async throws -> JSONObject {
        var tokenFeeScheduleUpdateTransaction = TokenFeeScheduleUpdateTransaction()

        tokenFeeScheduleUpdateTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        tokenFeeScheduleUpdateTransaction.customFees =
            try CommonParamsParser.getCustomFeesIfPresent(
                from: params.customFees, for: JSONRPCMethod.updateTokenFeeSchedule)
            ?? tokenFeeScheduleUpdateTransaction.customFees
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenFeeScheduleUpdateTransaction)

        let txReceipt = try await tokenFeeScheduleUpdateTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Handles the `updateToken` JSON-RPC method.
    internal func updateToken(from params: UpdateTokenParams) async throws -> JSONObject {
        var tokenUpdateTransaction = TokenUpdateTransaction()
        let method: JSONRPCMethod = .updateToken

        tokenUpdateTransaction.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        tokenUpdateTransaction.tokenName = params.name ?? tokenUpdateTransaction.tokenName
        tokenUpdateTransaction.tokenSymbol = params.symbol ?? tokenUpdateTransaction.tokenSymbol
        tokenUpdateTransaction.treasuryAccountId = try CommonParamsParser.getAccountIdIfPresent(
            from: params.treasuryAccountId)
        tokenUpdateTransaction.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        tokenUpdateTransaction.kycKey = try CommonParamsParser.getKeyIfPresent(from: params.kycKey)
        tokenUpdateTransaction.freezeKey = try CommonParamsParser.getKeyIfPresent(from: params.freezeKey)
        tokenUpdateTransaction.wipeKey = try CommonParamsParser.getKeyIfPresent(from: params.wipeKey)
        tokenUpdateTransaction.supplyKey = try CommonParamsParser.getKeyIfPresent(from: params.supplyKey)
        tokenUpdateTransaction.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(
            from: params.autoRenewAccountId)
        tokenUpdateTransaction.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod, for: method)
        tokenUpdateTransaction.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(
            from: params.expirationTime, for: method)
        tokenUpdateTransaction.tokenMemo = params.memo
        tokenUpdateTransaction.feeScheduleKey = try CommonParamsParser.getKeyIfPresent(from: params.feeScheduleKey)
        tokenUpdateTransaction.pauseKey = try CommonParamsParser.getKeyIfPresent(from: params.pauseKey)
        tokenUpdateTransaction.metadata = try params.metadata.flatMap {
            try $0.data(using: .utf8)
                ?? { throw JSONError.invalidParams("\(#function): metadata MUST be a UTF-8 string.") }()
        }
        tokenUpdateTransaction.metadataKey = try CommonParamsParser.getKeyIfPresent(from: params.metadataKey)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tokenUpdateTransaction)

        let txReceipt = try await tokenUpdateTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return .dictionary(["status": .string(txReceipt.status.description)])
    }
}
