// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TokenInfoQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_QueryAllDifferentKeys() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()

        let adminKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let freezeKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .decimals(TestConstants.testTokenDecimals)
                .initialSupply(0)
                .treasuryAccountId(accountId)
                .adminKey(.single(adminKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .freezeKey(.single(freezeKey.publicKey))
                .freezeDefault(false)
                .expirationTime(.now + .minutes(5))
                .sign(adminKey)
                .sign(accountKey),
            adminKey: adminKey,
            supplyKey: supplyKey,
            wipeKey: wipeKey
        )

        // When
        let info = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(testEnv.client)

        // Then
        assertTokenInfo(info, tokenId: tokenId)
        XCTAssertEqual(info.decimals, 3)
        XCTAssertEqual(info.treasuryAccountId, accountId)
        XCTAssertEqual(info.adminKey, .single(adminKey.publicKey))
        XCTAssertEqual(info.freezeKey, .single(freezeKey.publicKey))
        XCTAssertEqual(info.wipeKey, .single(wipeKey.publicKey))
        XCTAssertEqual(info.kycKey, .single(kycKey.publicKey))
        XCTAssertEqual(info.supplyKey, .single(supplyKey.publicKey))
        XCTAssertEqual(info.defaultFreezeStatus, false)
        XCTAssertEqual(info.defaultKycStatus, false)
        XCTAssertEqual(info.tokenType, .fungibleCommon)
        XCTAssertEqual(info.supplyType, .infinite)
    }

    internal func test_QueryNft() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()

        let adminKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(accountId)
                .adminKey(.single(adminKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .tokenType(.nonFungibleUnique)
                .tokenSupplyType(.finite)
                .maxSupply(TestConstants.testMaxSupply)
                .sign(adminKey)
                .sign(accountKey),
            adminKey: adminKey,
            supplyKey: supplyKey
        )

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(mintReceipt.serials)

        // When
        let info = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(testEnv.client)

        // Then
        assertTokenInfo(info, tokenId: tokenId)
        XCTAssertEqual(info.decimals, 0)
        XCTAssertEqual(info.totalSupply, UInt64(nftSerials.count))
        XCTAssertEqual(info.treasuryAccountId, accountId)
        XCTAssertEqual(info.adminKey, .single(adminKey.publicKey))
        XCTAssertEqual(info.supplyKey, .single(supplyKey.publicKey))
        XCTAssertNil(info.defaultFreezeStatus)
        XCTAssertNil(info.defaultKycStatus)
        XCTAssertEqual(info.tokenType, .nonFungibleUnique)
        XCTAssertEqual(info.supplyType, .finite)
        XCTAssertEqual(info.maxSupply, 5000)
    }

    internal func test_QueryCost() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let tokenId = try await createBasicFungibleToken(
            treasuryAccountId: accountId,
            treasuryKey: accountKey,
            initialSupply: 0
        )
        let query = TokenInfoQuery().tokenId(tokenId)
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        _ = try await query.paymentAmount(cost).execute(testEnv.client)
    }

    internal func test_QueryCostBigMax() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let tokenId = try await createBasicFungibleToken(
            treasuryAccountId: accountId,
            treasuryKey: accountKey,
            initialSupply: 0
        )

        let query = TokenInfoQuery().tokenId(tokenId).maxPaymentAmount(Hbar(1000))
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        _ = try await query.paymentAmount(cost).execute(testEnv.client)
    }

    internal func test_QueryCostSmallMaxFails() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let tokenId = try await createBasicFungibleToken(
            treasuryAccountId: accountId,
            treasuryKey: accountKey,
            initialSupply: 0
        )

        let query = TokenInfoQuery().tokenId(tokenId).maxPaymentAmount(.fromTinybars(1))
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        await assertMaxQueryPaymentExceeded(
            try await query.execute(testEnv.client),
            queryCost: cost,
            maxQueryPayment: .fromTinybars(1)
        )
    }

    internal func test_QueryCostInsufficientTxFeeFails() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let tokenId = try await createBasicFungibleToken(
            treasuryAccountId: accountId,
            treasuryKey: accountKey,
            initialSupply: 0
        )

        // When / Then
        await assertQueryPaymentPrecheckStatus(
            try await TokenInfoQuery()
                .tokenId(tokenId)
                .maxPaymentAmount(.fromTinybars(10000))
                .paymentAmount(.fromTinybars(1))
                .execute(testEnv.client),
            .insufficientTxFee
        )
    }
}
