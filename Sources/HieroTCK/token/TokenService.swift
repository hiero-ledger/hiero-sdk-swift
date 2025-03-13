// SPDX-License-Identifier: Apache-2.0

import Foundation

@testable import Hiero

/// Service class that services token service requests.
internal class TokenService {

    /// Singleton instance of TokenService.
    static let service = TokenService()

    /// Associate an account with (a) token(s). Can be called via JSON-RPC.
    internal func associateToken(_ params: AssociateTokenParams) async throws -> JSONObject {
        var tokenAssociateTransaction = TokenAssociateTransaction()

        tokenAssociateTransaction.accountId = try CommonParams.getAccountId(params.accountId)
        tokenAssociateTransaction.tokenIds =
            try CommonParams.getTokenIdList(params.tokenIds) ?? tokenAssociateTransaction.tokenIds
        try params.commonTransactionParams?.fillOutTransaction(&tokenAssociateTransaction)

        let txReceipt = try await tokenAssociateTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }

    /// Burn tokens. Can be called via JSON-RPC.
    internal func burnToken(_ params: BurnTokenParams) async throws -> JSONObject {
        var tokenBurnTransaction = TokenBurnTransaction()

        tokenBurnTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        tokenBurnTransaction.amount =
            try CommonParams.getAmount(params.amount, JSONRPCMethod.burnToken) ?? tokenBurnTransaction.amount
        tokenBurnTransaction.serials =
            try params.serialNumbers?.map {
                toUint64(try toInt($0, "serial number in serialNumbers list", JSONRPCMethod.burnToken))
            } ?? tokenBurnTransaction.serials
        try params.commonTransactionParams?.fillOutTransaction(&tokenBurnTransaction)

        let txReceipt = try await tokenBurnTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary([
            "status": JSONObject.string(txReceipt.status.description),
            "newTotalSupply": JSONObject.string(String(txReceipt.totalSupply)),
        ])
    }

    /// Create a token. Can be called via JSON-RPC.
    internal func createToken(_ params: CreateTokenParams) async throws -> JSONObject {
        var tokenCreateTransaction = TokenCreateTransaction()

        tokenCreateTransaction.name = params.name ?? tokenCreateTransaction.name
        tokenCreateTransaction.symbol = params.symbol ?? tokenCreateTransaction.symbol
        tokenCreateTransaction.decimals = params.decimals ?? tokenCreateTransaction.decimals
        tokenCreateTransaction.initialSupply =
            try CommonParams.getSdkUInt64(params.initialSupply, "initialSupply", JSONRPCMethod.createToken)
            ?? tokenCreateTransaction.initialSupply
        tokenCreateTransaction.treasuryAccountId = try CommonParams.getAccountId(params.treasuryAccountId)
        tokenCreateTransaction.adminKey = try CommonParams.getKey(params.adminKey)
        tokenCreateTransaction.kycKey = try CommonParams.getKey(params.kycKey)
        tokenCreateTransaction.freezeKey = try CommonParams.getKey(params.freezeKey)
        tokenCreateTransaction.wipeKey = try CommonParams.getKey(params.wipeKey)
        tokenCreateTransaction.supplyKey = try CommonParams.getKey(params.supplyKey)
        tokenCreateTransaction.freezeDefault = params.freezeDefault ?? tokenCreateTransaction.freezeDefault
        tokenCreateTransaction.expirationTime = try CommonParams.getExpirationTime(
            params.expirationTime, JSONRPCMethod.createToken)
        tokenCreateTransaction.autoRenewAccountId = try CommonParams.getAccountId(params.autoRenewAccountId)
        tokenCreateTransaction.autoRenewPeriod = try CommonParams.getAutoRenewPeriod(
            params.autoRenewPeriod, JSONRPCMethod.createToken)
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
            try CommonParams.getSdkUInt64(params.maxSupply, "maxSupply", JSONRPCMethod.createToken)
            ?? tokenCreateTransaction.maxSupply
        tokenCreateTransaction.feeScheduleKey = try CommonParams.getKey(params.feeScheduleKey)
        tokenCreateTransaction.customFees =
            try CommonParams.getCustomFees(params.customFees, JSONRPCMethod.createToken)
            ?? tokenCreateTransaction.customFees
        tokenCreateTransaction.pauseKey = try CommonParams.getKey(params.pauseKey)
        tokenCreateTransaction.metadata =
            try params.metadata.flatMap {
                try $0.data(using: .utf8)
                    ?? { throw JSONError.invalidParams("\(#function): metadata MUST be a UTF-8 string.") }()
            } ?? tokenCreateTransaction.metadata
        tokenCreateTransaction.metadataKey = try CommonParams.getKey(params.metadataKey)
        try params.commonTransactionParams?.fillOutTransaction(&tokenCreateTransaction)

        let txReceipt = try await tokenCreateTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary([
            "tokenId": JSONObject.string(txReceipt.tokenId!.toString()),
            "status": JSONObject.string(txReceipt.status.description),
        ])
    }

    /// Delete a token. Can be called via JSON-RPC.
    internal func deleteToken(_ params: DeleteTokenParams) async throws -> JSONObject {
        var tokenDeleteTransaction = TokenDeleteTransaction()

        tokenDeleteTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(&tokenDeleteTransaction)

        let txReceipt = try await tokenDeleteTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }

    /// Dissociate an account from (a) token(s). Can be called via JSON-RPC.
    internal func dissociateToken(_ params: DissociateTokenParams) async throws -> JSONObject {
        var tokenDissociateTransaction = TokenDissociateTransaction()

        tokenDissociateTransaction.accountId = try CommonParams.getAccountId(params.accountId)
        tokenDissociateTransaction.tokenIds =
            try CommonParams.getTokenIdList(params.tokenIds) ?? tokenDissociateTransaction.tokenIds
        try params.commonTransactionParams?.fillOutTransaction(&tokenDissociateTransaction)

        let txReceipt = try await tokenDissociateTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }

    /// Freeze a token on an account. Can be called via JSON-RPC.
    internal func freezeToken(_ params: FreezeTokenParams) async throws -> JSONObject {
        var tokenFreezeTransaction = TokenFreezeTransaction()

        tokenFreezeTransaction.accountId = try CommonParams.getAccountId(params.accountId)
        tokenFreezeTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(&tokenFreezeTransaction)

        let txReceipt = try await tokenFreezeTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }

    /// Grant KYC of a token to an account. Can be called via JSON-RPC.
    internal func grantTokenKyc(_ params: GrantTokenKycParams) async throws -> JSONObject {
        var tokenGrantKycTransaction = TokenGrantKycTransaction()

        tokenGrantKycTransaction.accountId = try CommonParams.getAccountId(params.accountId)
        tokenGrantKycTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(&tokenGrantKycTransaction)

        let txReceipt = try await tokenGrantKycTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }

    /// Mint tokens. Can be called via JSON-RPC.
    internal func mintToken(_ params: MintTokenParams) async throws -> JSONObject {
        var tokenMintTransaction = TokenMintTransaction()

        tokenMintTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        tokenMintTransaction.amount =
            try CommonParams.getAmount(params.amount, JSONRPCMethod.mintToken) ?? tokenMintTransaction.amount
        tokenMintTransaction.metadata =
            try params.metadata?.map {
                try Data(hexEncoded: $0)
                    ?? { throw JSONError.invalidParams("\(#function): metadata MUST be a hex-encoded string.") }()
            } ?? tokenMintTransaction.metadata
        try params.commonTransactionParams?.fillOutTransaction(&tokenMintTransaction)

        let txReceipt = try await tokenMintTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(
            [
                "status": JSONObject.string(txReceipt.status.description),
                "newTotalSupply": JSONObject.string(String(txReceipt.totalSupply)),
            ].merging(
                txReceipt.serials.map { ["serialNumbers": JSONObject.list($0.map { JSONObject.string(String($0)) })] }
                    ?? [:]
            ) { _, new in new })

    }

    /// Pause a token. Can be called via JSON-RPC.
    internal func pauseToken(_ params: PauseTokenParams) async throws -> JSONObject {
        var tokenPauseTransaction = TokenPauseTransaction()

        tokenPauseTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(&tokenPauseTransaction)

        let txReceipt = try await tokenPauseTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }

    /// Revoke KYC of a token from an account. Can be called via JSON-RPC.
    internal func revokeTokenKyc(_ params: RevokeTokenKycParams) async throws -> JSONObject {
        var tokenRevokeKycTransaction = TokenRevokeKycTransaction()

        tokenRevokeKycTransaction.accountId = try CommonParams.getAccountId(params.accountId)
        tokenRevokeKycTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(&tokenRevokeKycTransaction)

        let txReceipt = try await tokenRevokeKycTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }

    /// Unfreeze a token from an account. Can be called via JSON-RPC.
    internal func unfreezeToken(_ params: UnfreezeTokenParams) async throws -> JSONObject {
        var tokenUnfreezeTransaction = TokenUnfreezeTransaction()

        tokenUnfreezeTransaction.accountId = try CommonParams.getAccountId(params.accountId)
        tokenUnfreezeTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(&tokenUnfreezeTransaction)

        let txReceipt = try await tokenUnfreezeTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }

    /// Unpause a token. Can be called via JSON-RPC.
    internal func unpauseToken(_ params: UnpauseTokenParams) async throws -> JSONObject {
        var tokenUnpauseTransaction = TokenUnpauseTransaction()

        tokenUnpauseTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        try params.commonTransactionParams?.fillOutTransaction(&tokenUnpauseTransaction)

        let txReceipt = try await tokenUnpauseTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }

    /// Update a token's fee schedule. Can be called via JSON-RPC.
    internal func updateTokenFeeSchedule(_ params: UpdateTokenFeeScheduleParams) async throws -> JSONObject {
        var tokenFeeScheduleUpdateTransaction = TokenFeeScheduleUpdateTransaction()

        tokenFeeScheduleUpdateTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        tokenFeeScheduleUpdateTransaction.customFees =
            try CommonParams.getCustomFees(params.customFees, JSONRPCMethod.updateTokenFeeSchedule)
            ?? tokenFeeScheduleUpdateTransaction.customFees
        try params.commonTransactionParams?.fillOutTransaction(&tokenFeeScheduleUpdateTransaction)

        let txReceipt = try await tokenFeeScheduleUpdateTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }

    /// Update a token. Can be called via JSON-RPC.
    internal func updateToken(_ params: UpdateTokenParams) async throws -> JSONObject {
        var tokenUpdateTransaction = TokenUpdateTransaction()

        tokenUpdateTransaction.tokenId = try CommonParams.getTokenId(params.tokenId)
        tokenUpdateTransaction.tokenName = params.name ?? tokenUpdateTransaction.tokenName
        tokenUpdateTransaction.tokenSymbol = params.symbol ?? tokenUpdateTransaction.tokenSymbol
        tokenUpdateTransaction.treasuryAccountId = try CommonParams.getAccountId(params.treasuryAccountId)
        tokenUpdateTransaction.adminKey = try CommonParams.getKey(params.adminKey)
        tokenUpdateTransaction.kycKey = try CommonParams.getKey(params.kycKey)
        tokenUpdateTransaction.freezeKey = try CommonParams.getKey(params.freezeKey)
        tokenUpdateTransaction.wipeKey = try CommonParams.getKey(params.wipeKey)
        tokenUpdateTransaction.supplyKey = try CommonParams.getKey(params.supplyKey)
        tokenUpdateTransaction.autoRenewAccountId = try CommonParams.getAccountId(params.autoRenewAccountId)
        tokenUpdateTransaction.autoRenewPeriod = try CommonParams.getAutoRenewPeriod(
            params.autoRenewPeriod, JSONRPCMethod.updateToken)
        tokenUpdateTransaction.expirationTime = try CommonParams.getExpirationTime(
            params.expirationTime, JSONRPCMethod.updateToken)
        tokenUpdateTransaction.tokenMemo = params.memo
        tokenUpdateTransaction.feeScheduleKey = try CommonParams.getKey(params.feeScheduleKey)
        tokenUpdateTransaction.pauseKey = try CommonParams.getKey(params.pauseKey)
        tokenUpdateTransaction.metadata = try params.metadata.flatMap {
            try $0.data(using: .utf8)
                ?? { throw JSONError.invalidParams("\(#function): metadata MUST be a UTF-8 string.") }()
        }
        tokenUpdateTransaction.metadataKey = try CommonParams.getKey(params.metadataKey)
        try params.commonTransactionParams?.fillOutTransaction(&tokenUpdateTransaction)

        let txReceipt = try await tokenUpdateTransaction.execute(SDKClient.client.getClient()).getReceipt(
            SDKClient.client.getClient())
        return JSONObject.dictionary(["status": JSONObject.string(txReceipt.status.description)])
    }
}
