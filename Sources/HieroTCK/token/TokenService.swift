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
                    throw JSONError.invalidParams("Hbar transfers MUST NOT be provided in a token airdrop.")
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
        try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds).assignIfPresent(to: &tx.tokenIds)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `burnToken` JSON-RPC method.
    internal static func burnToken(from params: BurnTokenParams) async throws -> JSONObject {
        var tx = TokenBurnTransaction()
        let method: JSONRPCMethod = .burnToken

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try CommonParamsParser.getAmountIfPresent(from: params.amount, for: method).assignIfPresent(to: &tx.amount)
        try params.serialNumbers.assignIfPresent(to: &tx.serials) { serials in
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

        params.name.assignIfPresent(to: &tx.name)
        params.symbol.assignIfPresent(to: &tx.symbol)
        params.decimals.assignIfPresent(to: &tx.decimals)
        try JSONRPCParam.parseUInt64IfPresentReinterpretingSigned(
            name: "initialSupply",
            from: params.initialSupply,
            for: method
        ).assignIfPresent(to: &tx.initialSupply)
        tx.treasuryAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.treasuryAccountId)
        tx.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        tx.kycKey = try CommonParamsParser.getKeyIfPresent(from: params.kycKey)
        tx.freezeKey = try CommonParamsParser.getKeyIfPresent(from: params.freezeKey)
        tx.wipeKey = try CommonParamsParser.getKeyIfPresent(from: params.wipeKey)
        tx.supplyKey = try CommonParamsParser.getKeyIfPresent(from: params.supplyKey)
        params.freezeDefault.assignIfPresent(to: &tx.freezeDefault)
        tx.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(from: params.expirationTime, for: method)
        tx.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.autoRenewAccountId)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod,
            for: method)
        params.memo.assignIfPresent(to: &tx.tokenMemo)
        try JSONRPCParam.parseEnumIfPresent(
            name: "tokenType",
            from: params.tokenType,
            map: ["ft": .fungibleCommon, "nft": .nonFungibleUnique],
            for: method
        ).assignIfPresent(to: &tx.tokenType)
        try JSONRPCParam.parseEnumIfPresent(
            name: "supplyType",
            from: params.supplyType,
            map: ["finite": .finite, "infinite": .infinite],
            for: method
        ).assignIfPresent(to: &tx.tokenSupplyType)
        try params.maxSupply.assignIfPresent(to: &tx.maxSupply) {
            try JSONRPCParam.parseUInt64ReinterpretingSigned(name: "maxSupply", from: $0, for: method)
        }
        tx.feeScheduleKey = try CommonParamsParser.getKeyIfPresent(from: params.feeScheduleKey)
        try CommonParamsParser.getHieroAnyCustomFeesIfPresent(from: params.customFees, for: method).assignIfPresent(
            to: &tx.customFees)
        tx.pauseKey = try CommonParamsParser.getKeyIfPresent(from: params.pauseKey)
        try CommonParamsParser.getMetadataIfPresent(from: params.metadata, for: method).assignIfPresent(
            to: &tx.metadata)
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
        try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds).assignIfPresent(to: &tx.tokenIds)
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
        try CommonParamsParser.getAmountIfPresent(from: params.amount, for: method).assignIfPresent(to: &tx.amount)
        try params.metadata.assignIfPresent(to: &tx.metadata) { metadata in
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
            try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds).assignIfPresent(to: &tokenIds)

            for (index, serial) in serials.enumerated() {
                let nftId = NftId(
                    tokenId: tokenIds[0],
                    serial: try CommonParamsParser.getSerialNumber(from: serial, for: .rejectToken, index: index))
                tx.addNftId(nftId)
            }
        } else {
            try CommonParamsParser.getTokenIdsIfPresent(from: params.tokenIds).assignIfPresent(to: &tx.tokenIds)
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
        ).assignIfPresent(to: &tx.customFees)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `updateToken` JSON-RPC method.
    internal static func updateToken(from params: UpdateTokenParams) async throws -> JSONObject {
        var tx = TokenUpdateTransaction()
        let method: JSONRPCMethod = .updateToken

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        params.name.assignIfPresent(to: &tx.tokenName)
        params.symbol.assignIfPresent(to: &tx.tokenSymbol)
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

    /// Handles the `wipeToken` JSON-RPC method.
    internal static func wipeToken(from params: WipeTokenParams) async throws -> JSONObject {
        var tx = TokenWipeTransaction()
        let method: JSONRPCMethod = .wipeToken

        tx.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        tx.accountId = try CommonParamsParser.getAccountIdIfPresent(from: params.accountId)
        try CommonParamsParser.getAmountIfPresent(from: params.amount, for: method).assignIfPresent(to: &tx.amount)
        try params.serialNumbers.assignIfPresent(to: &tx.serials) { serials in
            try serials.enumerated().map { index, serial in
                try CommonParamsParser.getSerialNumber(from: serial, for: method, index: index)
            }
        }
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `getTokenInfo` JSON-RPC method.
    internal static func getTokenInfo(from params: GetTokenInfoParams) async throws -> JSONObject {
        let query = TokenInfoQuery()
        let method: JSONRPCMethod = .getTokenInfo
        query.tokenId = try CommonParamsParser.getTokenIdIfPresent(from: params.tokenId)
        try CommonParamsParser.assignQueryPaymentIfPresent(from: params.queryPayment, to: query, for: method)
        query.maxPaymentAmount(
            try CommonParamsParser.getMaxQueryPaymentIfPresent(from: params.maxQueryPayment, for: method))

        let result = try await SDKClient.client.executeQuery(query)
        var response: [String: JSONObject] = [:]

        response["tokenId"] = .string(result.tokenId.toString())
        response["name"] = .string(result.name)
        response["symbol"] = .string(result.symbol)
        response["decimals"] = .int(Int64(result.decimals))
        response["totalSupply"] = .string(String(result.totalSupply))
        response["treasuryAccountId"] = .string(result.treasuryAccountId.toString())

        result.adminKey.ifPresent { response["adminKey"] = .string(keyToString($0)) }
        result.kycKey.ifPresent { response["kycKey"] = .string(keyToString($0)) }
        result.freezeKey.ifPresent { response["freezeKey"] = .string(keyToString($0)) }
        result.wipeKey.ifPresent { response["wipeKey"] = .string(keyToString($0)) }
        result.supplyKey.ifPresent { response["supplyKey"] = .string(keyToString($0)) }
        result.feeScheduleKey.ifPresent { response["feeScheduleKey"] = .string(keyToString($0)) }
        result.pauseKey.ifPresent { response["pauseKey"] = .string(keyToString($0)) }
        result.metadataKey.ifPresent { response["metadataKey"] = .string(keyToString($0)) }

        response["defaultFreezeStatus"] = result.defaultFreezeStatus.map { .bool($0) } ?? .null
        response["defaultKycStatus"] = result.defaultKycStatus.map { .bool($0) } ?? .null
        response["pauseStatus"] = .string(pauseStatusToString(result.pauseStatus))
        response["isDeleted"] = .bool(result.isDeleted)
        result.autoRenewAccount.ifPresent { response["autoRenewAccountId"] = .string($0.toString()) }
        result.autoRenewPeriod.ifPresent { response["autoRenewPeriod"] = .string(String($0.seconds)) }
        result.expirationTime.ifPresent { response["expirationTime"] = .string(String($0.seconds)) }

        response["tokenMemo"] = .string(result.tokenMemo)
        response["customFees"] = .list(result.customFees.map { serializeCustomFee($0) })
        response["tokenType"] = .string(tokenTypeToString(result.tokenType))
        response["supplyType"] = .string(supplyTypeToString(result.supplyType))
        response["maxSupply"] = .string(String(result.maxSupply))
        response["metadata"] = .string(result.metadata.map { String(format: "%02x", $0) }.joined())
        response["ledgerId"] = .string(result.ledgerId.description)

        return .dictionary(response)
    }

    // MARK: - Private Helpers

    private static func keyToString(_ key: Key) -> String {
        if case .single(let publicKey) = key {
            return publicKey.toStringDer()
        }
        // For complex keys, return the protobuf bytes as hex
        return key.toBytes().map { String(format: "%02x", $0) }.joined()
    }

    private static func pauseStatusToString(_ pauseStatus: Bool?) -> String {
        switch pauseStatus {
        case .none: return "NOT_APPLICABLE"
        case .some(true): return "PAUSED"
        case .some(false): return "UNPAUSED"
        }
    }

    private static func tokenTypeToString(_ tokenType: TokenType) -> String {
        switch tokenType {
        case .fungibleCommon: return "FUNGIBLE_COMMON"
        case .nonFungibleUnique: return "NON_FUNGIBLE_UNIQUE"
        }
    }

    private static func supplyTypeToString(_ supplyType: TokenSupplyType) -> String {
        switch supplyType {
        case .infinite: return "INFINITE"
        case .finite: return "FINITE"
        }
    }

    private static func serializeCustomFee(_ fee: AnyCustomFee) -> JSONObject {
        var result: [String: JSONObject] = [:]

        fee.feeCollectorAccountId.ifPresent { result["feeCollectorAccountId"] = .string($0.toString()) }
        result["allCollectorsAreExempt"] = .bool(fee.allCollectorsAreExempt)

        switch fee {
        case .fixed(let fixedFee):
            var fixedFeeObj: [String: JSONObject] = [:]
            fixedFeeObj["amount"] = .string(String(fixedFee.amount))
            if let denominatingTokenId = fixedFee.denominatingTokenId {
                fixedFeeObj["denominatingTokenId"] = .string(denominatingTokenId.toString())
            }
            result["fixedFee"] = .dictionary(fixedFeeObj)

        case .fractional(let fractionalFee):
            var fractionalFeeObj: [String: JSONObject] = [:]
            fractionalFeeObj["numerator"] = .string(String(fractionalFee.numerator))
            fractionalFeeObj["denominator"] = .string(String(fractionalFee.denominator))
            fractionalFeeObj["minimumAmount"] = .string(String(fractionalFee.minimumAmount))
            fractionalFeeObj["maximumAmount"] = .string(String(fractionalFee.maximumAmount))
            fractionalFeeObj["assessmentMethod"] = .string(
                fractionalFee.assessmentMethod == .exclusive ? "exclusive" : "inclusive")
            result["fractionalFee"] = .dictionary(fractionalFeeObj)

        case .royalty(let royaltyFee):
            var royaltyFeeObj: [String: JSONObject] = [:]
            royaltyFeeObj["numerator"] = .string(String(royaltyFee.numerator))
            royaltyFeeObj["denominator"] = .string(String(royaltyFee.denominator))
            if let fallbackFee = royaltyFee.fallbackFee {
                var fallbackFeeObj: [String: JSONObject] = [:]
                fallbackFeeObj["amount"] = .string(String(fallbackFee.amount))
                if let denominatingTokenId = fallbackFee.denominatingTokenId {
                    fallbackFeeObj["denominatingTokenId"] = .string(denominatingTokenId.toString())
                }
                royaltyFeeObj["fallbackFee"] = .dictionary(fallbackFeeObj)
            }
            result["royaltyFee"] = .dictionary(royaltyFeeObj)
        }

        return .dictionary(result)
    }
}
