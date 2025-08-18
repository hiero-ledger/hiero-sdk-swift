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
        var tx = TokenAssociateTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        setIfPresent(&tx.tokenIds, to: try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds))
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `burnToken` JSON-RPC method.
    internal func burnToken(from params: BurnTokenParams) async throws -> JSONObject {
        var tx = TokenBurnTransaction()
        let method: JSONRPCMethod = .burnToken

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        setIfPresent(&tx.amount, to: try CommonParamsParser.getAmountIfPresent(from: params.amount, for: method))
        setIfPresent(
            &tx.serials,
            to: try params.serialNumbers?.enumerated().map { index, serial in
                try CommonParamsParser.getSerialNumber(from: serial, for: method, index: index)
            })
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary([
            "status": .string(txReceipt.status.description),
            "newTotalSupply": .string(String(txReceipt.totalSupply)),
        ])
    }

    /// Handles the `createToken` JSON-RPC method.
    internal func createToken(from params: CreateTokenParams) async throws -> JSONObject {
        var tx = TokenCreateTransaction()
        let method: JSONRPCMethod = .createToken

        setIfPresent(&tx.name, to: params.name)
        setIfPresent(&tx.symbol, to: params.symbol)
        setIfPresent(&tx.decimals, to: params.decimals)
        setIfPresent(
            &tx.initialSupply,
            to: try parseUInt64IfPresentReinterpretingSigned(
                name: "initialSupply", from: params.initialSupply, for: method))
        tx.treasuryAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.treasuryAccountId)
        tx.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        tx.kycKey = try CommonParamsParser.getKeyIfPresent(from: params.kycKey)
        tx.freezeKey = try CommonParamsParser.getKeyIfPresent(from: params.freezeKey)
        tx.wipeKey = try CommonParamsParser.getKeyIfPresent(from: params.wipeKey)
        tx.supplyKey = try CommonParamsParser.getKeyIfPresent(from: params.supplyKey)
        setIfPresent(&tx.freezeDefault, to: params.freezeDefault)
        tx.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(from: params.expirationTime, for: method)
        tx.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.autoRenewAccountId)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod, for: method)
        setIfPresent(&tx.tokenMemo, to: params.memo)
        setIfPresent(
            &tx.tokenType,
            to: try params.tokenType.flatMap {
                try ["ft", "nft"].contains($0)
                    ? ($0 == "ft" ? .fungibleCommon : .nonFungibleUnique)
                    : { throw JSONError.invalidParams("\(#function): tokenType MUST be 'ft' or 'nft'.") }()
            })
        setIfPresent(
            &tx.tokenSupplyType,
            to: try params.supplyType.flatMap {
                try ["finite", "infinite"].contains($0)
                    ? ($0 == "finite" ? .finite : .infinite)
                    : { throw JSONError.invalidParams("\(#function): supplyType MUST be 'finite' or 'infinite'.") }()
            })
        setIfPresent(
            &tx.maxSupply,
            to: try parseUInt64IfPresentReinterpretingSigned(name: "maxSupply", from: params.maxSupply, for: method))
        tx.feeScheduleKey = try CommonParamsParser.getKeyIfPresent(from: params.feeScheduleKey)
        setIfPresent(
            &tx.customFees, to: try CommonParamsParser.getCustomFeesIfPresent(from: params.customFees, for: method))
        tx.pauseKey = try CommonParamsParser.getKeyIfPresent(from: params.pauseKey)
        setIfPresent(&tx.metadata, to: try CommonParamsParser.getMetadataIfPresent(from: params.metadata, for: method))
        tx.metadataKey = try CommonParamsParser.getKeyIfPresent(from: params.metadataKey)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary([
            "tokenId": .string(txReceipt.tokenId!.toString()),
            "status": .string(txReceipt.status.description),
        ])
    }

    /// Handles the `deleteToken` JSON-RPC method.
    internal func deleteToken(from params: DeleteTokenParams) async throws -> JSONObject {
        var tx = TokenDeleteTransaction()

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `dissociateToken` JSON-RPC method.
    internal func dissociateToken(from params: DissociateTokenParams) async throws -> JSONObject {
        var tx = TokenDissociateTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        setIfPresent(&tx.tokenIds, to: try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds))
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `freezeToken` JSON-RPC method.
    internal func freezeToken(from params: FreezeTokenParams) async throws -> JSONObject {
        var tx = TokenFreezeTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `grantTokenKyc` JSON-RPC method.
    internal func grantTokenKyc(from params: GrantTokenKycParams) async throws -> JSONObject {
        var tx = TokenGrantKycTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `mintToken` JSON-RPC method.
    internal func mintToken(from params: MintTokenParams) async throws -> JSONObject {
        var tx = TokenMintTransaction()
        let method: JSONRPCMethod = .mintToken

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        setIfPresent(&tx.amount, to: try CommonParamsParser.getAmountIfPresent(from: params.amount, for: method))
        setIfPresent(
            &tx.metadata,
            to: try params.metadata?.enumerated().map { idx, param in
                try CommonParamsParser.parseMetadataString(name: "metadata[\(idx)]", from: param, for: method)
            })
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

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
    internal func pauseToken(from params: PauseTokenParams) async throws -> JSONObject {
        var tx = TokenPauseTransaction()

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `revokeTokenKyc` JSON-RPC method.
    internal func revokeTokenKyc(from params: RevokeTokenKycParams) async throws -> JSONObject {
        var tx = TokenRevokeKycTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `unfreezeToken` JSON-RPC method.
    internal func unfreezeToken(from params: UnfreezeTokenParams) async throws -> JSONObject {
        var tx = TokenUnfreezeTransaction()

        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `unpauseToken` JSON-RPC method.
    internal func unpauseToken(from params: UnpauseTokenParams) async throws -> JSONObject {
        var tx = TokenUnpauseTransaction()

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `updateTokenFeeSchedule` JSON-RPC method.
    internal func updateTokenFeeSchedule(from params: UpdateTokenFeeScheduleParams) async throws -> JSONObject {
        var tx = TokenFeeScheduleUpdateTransaction()

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        setIfPresent(
            &tx.customFees,
            to: try CommonParamsParser.getCustomFeesIfPresent(
                from: params.customFees, for: JSONRPCMethod.updateTokenFeeSchedule))
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `updateToken` JSON-RPC method.
    internal func updateToken(from params: UpdateTokenParams) async throws -> JSONObject {
        var tx = TokenUpdateTransaction()
        let method: JSONRPCMethod = .updateToken

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        setIfPresent(&tx.tokenName, to: params.name)
        setIfPresent(&tx.tokenSymbol, to: params.symbol)
        tx.treasuryAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.treasuryAccountId)
        tx.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        tx.kycKey = try CommonParamsParser.getKeyIfPresent(from: params.kycKey)
        tx.freezeKey = try CommonParamsParser.getKeyIfPresent(from: params.freezeKey)
        tx.wipeKey = try CommonParamsParser.getKeyIfPresent(from: params.wipeKey)
        tx.supplyKey = try CommonParamsParser.getKeyIfPresent(from: params.supplyKey)
        tx.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.autoRenewAccountId)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod, for: method)
        tx.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(from: params.expirationTime, for: method)
        tx.tokenMemo = params.memo
        tx.feeScheduleKey = try CommonParamsParser.getKeyIfPresent(from: params.feeScheduleKey)
        tx.pauseKey = try CommonParamsParser.getKeyIfPresent(from: params.pauseKey)
        tx.metadata = try CommonParamsParser.getMetadataIfPresent(from: params.metadata, for: method)
        tx.metadataKey = try CommonParamsParser.getKeyIfPresent(from: params.metadataKey)
        try params.commonTransactionParams?.fillOutTransaction(transaction: &tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }
}
