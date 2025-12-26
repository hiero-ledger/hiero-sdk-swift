// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TokenCreateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_AllOperatorKeys() async throws {
        // Given / When
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(0)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .freezeKey(.single(testEnv.operator.privateKey.publicKey))
                .wipeKey(.single(testEnv.operator.privateKey.publicKey))
                .kycKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey))
                .feeScheduleKey(.single(testEnv.operator.privateKey.publicKey))
                .freezeDefault(false),
            adminKey: testEnv.operator.privateKey
        )

        // Then
        let info = try await TokenInfoQuery(tokenId: tokenId).execute(testEnv.client)
        assertTokenInfo(info, tokenId: tokenId)
    }

    internal func test_MinimalProperties() async throws {
        // Given / When
        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .expirationTime(.now + .minutes(5))
        )

        // Then
        let info = try await TokenInfoQuery(tokenId: tokenId).execute(testEnv.client)
        assertTokenInfo(info, tokenId: tokenId)
    }

    internal func test_MissingNameFail() async throws {
        // Given / When / Then
        await assertReceiptStatus(
            try await TokenCreateTransaction()
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .expirationTime(.now + .minutes(5))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .missingTokenName
        )
    }

    internal func test_MissingSymbolFail() async throws {
        // Given / When / Then
        await assertReceiptStatus(
            try await TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .treasuryAccountId(testEnv.operator.accountId)
                .expirationTime(.now + .minutes(5))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .missingTokenSymbol
        )
    }

    internal func test_MissingTreasuryAccountIdFail() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .expirationTime(.now + .minutes(5))
                .execute(testEnv.client),
            .invalidTreasuryAccountForToken
        )
    }

    internal func test_MissingTreasuryAccountIdSigFail() async throws {
        // Given / When / Then
        await assertReceiptStatus(
            try await TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(AccountId(num: 999))
                .expirationTime(.now + .minutes(5))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_AdminKeySigFail() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()

        // When / Then
        await assertReceiptStatus(
            try await TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_CustomFees() async throws {
        // Given
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey)),
            keys: [testEnv.operator.privateKey]
        )

        let customFees: [AnyCustomFee] = [
            .fixed(.init(amount: 11, feeCollectorAccountId: accountId)),
            .fractional(.init(amount: "1/20", minimumAmount: 1, maximumAmount: 10, feeCollectorAccountId: accountId)),
        ]

        // When
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .customFees(customFees)
                .expirationTime(.now + .minutes(5)),
            adminKey: testEnv.operator.privateKey
        )

        // Then
        let info = try await TokenInfoQuery(tokenId: tokenId).execute(testEnv.client)
        assertTokenInfo(info, tokenId: tokenId)
    }

    internal func test_TooManyCustomFeesFail() async throws {
        // Given
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey)),
            keys: [testEnv.operator.privateKey]
        )

        let customFees: [AnyCustomFee] = Array(
            repeating: .fixed(.init(amount: 10, feeCollectorAccountId: accountId)), count: 11)

        // When / Then
        await assertReceiptStatus(
            try await TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .customFees(customFees)
                .expirationTime(.now + .minutes(5))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .customFeesListTooLong
        )
    }

    internal func test_TenFixedFees() async throws {
        // Given
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey)),
            keys: [testEnv.operator.privateKey]
        )

        let customFees: [AnyCustomFee] = Array(
            repeating: .fixed(.init(amount: 10, feeCollectorAccountId: accountId)), count: 10)

        // When
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .customFees(customFees)
                .expirationTime(.now + .minutes(5)),
            adminKey: testEnv.operator.privateKey
        )

        // Then
        let info = try await TokenInfoQuery(tokenId: tokenId).execute(testEnv.client)
        assertTokenInfo(info, tokenId: tokenId)
    }

    internal func test_TenFractionalFees() async throws {
        // Given
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey)),
            keys: [testEnv.operator.privateKey]
        )

        let customFees: [AnyCustomFee] = Array(
            repeating: .fractional(
                .init(amount: "1/20", minimumAmount: 1, maximumAmount: 10, feeCollectorAccountId: accountId)),
            count: 10)

        // When
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .customFees(customFees)
                .expirationTime(.now + .minutes(5)),
            adminKey: testEnv.operator.privateKey
        )

        // Then
        let info = try await TokenInfoQuery(tokenId: tokenId).execute(testEnv.client)
        assertTokenInfo(info, tokenId: tokenId)
    }

    internal func test_FractionalFeeMinBiggerThanMaxFail() async throws {
        // Given
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey)),
            keys: [testEnv.operator.privateKey]
        )

        let customFees: [AnyCustomFee] = [
            .fractional(.init(amount: "1/3", minimumAmount: 3, maximumAmount: 2, feeCollectorAccountId: accountId))
        ]

        // When / Then
        await assertReceiptStatus(
            try await TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .customFees(customFees)
                .expirationTime(.now + .minutes(5))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .fractionalFeeMaxAmountLessThanMinAmount
        )
    }

    internal func test_Nfts() async throws {
        // Given
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey)),
            keys: [testEnv.operator.privateKey]
        )

        // When
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .freezeKey(.single(testEnv.operator.privateKey.publicKey))
                .wipeKey(.single(testEnv.operator.privateKey.publicKey))
                .kycKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey))
                .freezeDefault(false),
            adminKey: testEnv.operator.privateKey
        )

        // Then
        let info = try await TokenInfoQuery(tokenId: tokenId).execute(testEnv.client)
        assertTokenInfo(info, tokenId: tokenId)
        XCTAssertEqual(info.tokenType, .nonFungibleUnique)
    }

    internal func test_RoyalFee() async throws {
        // Given
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey)),
            keys: [testEnv.operator.privateKey]
        )

        let customFees: [AnyCustomFee] = [
            .royalty(
                .init(
                    exchangeValue: "1/10", fallbackFee: FixedFee(amount: 1), feeCollectorAccountId: accountId,
                    allCollectorsAreExempt: false))
        ]

        // When
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .customFees(customFees)
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey))
                .freezeDefault(false),
            adminKey: testEnv.operator.privateKey
        )

        // Then
        let info = try await TokenInfoQuery(tokenId: tokenId).execute(testEnv.client)
        assertTokenInfo(info, tokenId: tokenId)
    }
}
