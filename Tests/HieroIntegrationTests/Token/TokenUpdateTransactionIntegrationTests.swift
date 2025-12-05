// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TokenUpdateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .sign(adminKey),
            adminKey: adminKey
        )

        // When
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .tokenName("aaaa")
            .tokenSymbol("A")
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await TokenInfoQuery(tokenId: tokenId).execute(testEnv.client)

        XCTAssertEqual(info.tokenId, tokenId)
        XCTAssertEqual(info.name, "aaaa")
        XCTAssertEqual(info.symbol, "A")
        XCTAssertEqual(info.adminKey, Key.single(adminKey.publicKey))
    }

    internal func test_ImmutableTokenFails() async throws {
        // Given
        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(testEnv.operator.accountId)
                .expirationTime(.now + .minutes(5))
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .tokenName("aaaa")
                .tokenSymbol("A")
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenIsImmutable
        )
    }

    internal func test_UpdateImmutableTokenMetadata() async throws {
        // Given
        let initialMetadata = Data([1])
        let updatedMetadata = Data([1, 2])
        let metadataKey = PrivateKey.generateEd25519()
        let adminKey = PrivateKey.generateEd25519()

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .metadata(initialMetadata)
                .metadataKey(.single(metadataKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey
        )

        // When
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .metadata(updatedMetadata)
            .freezeWith(testEnv.client)
            .sign(metadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let tokenInfoAfterMetadataUpdate = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(testEnv.client)
        XCTAssertEqual(tokenInfoAfterMetadataUpdate.metadata, updatedMetadata)
    }

    internal func test_UpdateKeysWithAdminSigAndNoValidation() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
                .freezeWith(testEnv.client)
                .sign(adminKey)
        )

        // When
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .adminKey(.keyList(KeyList()))
            .freezeKey(.keyList(KeyList()))
            .wipeKey(.keyList(KeyList()))
            .kycKey(.keyList(KeyList()))
            .supplyKey(.keyList(KeyList()))
            .pauseKey(.keyList(KeyList()))
            .feeScheduleKey(.keyList(KeyList()))
            .metadataKey(.keyList(KeyList()))
            .keyVerificationMode(TokenKeyValidation.noValidation)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertNil(tokenInfo.adminKey)
        XCTAssertNil(tokenInfo.freezeKey)
        XCTAssertNil(tokenInfo.wipeKey)
        XCTAssertNil(tokenInfo.kycKey)
        XCTAssertNil(tokenInfo.supplyKey)
        XCTAssertNil(tokenInfo.pauseKey)
        XCTAssertNil(tokenInfo.feeScheduleKey)
        XCTAssertNil(tokenInfo.metadataKey)
    }

    internal func test_RemoveKeysWithAdminSigAndFullValidation() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
                .freezeWith(testEnv.client)
                .sign(adminKey)
        )

        // When
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .adminKey(.keyList(KeyList()))
            .freezeKey(.keyList(KeyList()))
            .wipeKey(.keyList(KeyList()))
            .kycKey(.keyList(KeyList()))
            .supplyKey(.keyList(KeyList()))
            .pauseKey(.keyList(KeyList()))
            .feeScheduleKey(.keyList(KeyList()))
            .metadataKey(.keyList(KeyList()))
            .keyVerificationMode(TokenKeyValidation.fullValidation)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertNil(tokenInfo.adminKey)
        XCTAssertNil(tokenInfo.freezeKey)
        XCTAssertNil(tokenInfo.wipeKey)
        XCTAssertNil(tokenInfo.kycKey)
        XCTAssertNil(tokenInfo.supplyKey)
        XCTAssertNil(tokenInfo.pauseKey)
        XCTAssertNil(tokenInfo.feeScheduleKey)
        XCTAssertNil(tokenInfo.metadataKey)
    }

    internal func test_RevertKeysFromUnusableWithAdminSigAndFullValidation() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey
        )

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // When
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .freezeKey(.single(unusableKey))
            .wipeKey(.single(unusableKey))
            .kycKey(.single(unusableKey))
            .supplyKey(.single(unusableKey))
            .pauseKey(.single(unusableKey))
            .feeScheduleKey(.single(unusableKey))
            .metadataKey(.single(unusableKey))
            .keyVerificationMode(TokenKeyValidation.fullValidation)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfo.freezeKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.wipeKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.kycKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.supplyKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.pauseKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.feeScheduleKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.metadataKey, .single(unusableKey))
    }

    internal func test_UpdateLowPrivilegeKeysWithAdminSigAndFullValidation() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let newFreezeKey = PrivateKey.generateEd25519()
        let newWipeKey = PrivateKey.generateEd25519()
        let newSupplyKey = PrivateKey.generateEd25519()
        let newPauseKey = PrivateKey.generateEd25519()
        let newKycKey = PrivateKey.generateEd25519()
        let newFeeScheduleKey = PrivateKey.generateEd25519()
        let newMetadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey
        )

        // When
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .freezeKey(.single(newFreezeKey.publicKey))
            .wipeKey(.single(newWipeKey.publicKey))
            .kycKey(.single(newKycKey.publicKey))
            .supplyKey(.single(newSupplyKey.publicKey))
            .pauseKey(.single(newPauseKey.publicKey))
            .feeScheduleKey(.single(newFeeScheduleKey.publicKey))
            .metadataKey(.single(newMetadataKey.publicKey))
            .keyVerificationMode(TokenKeyValidation.fullValidation)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .sign(newFreezeKey)
            .sign(newWipeKey)
            .sign(newKycKey)
            .sign(newSupplyKey)
            .sign(newPauseKey)
            .sign(newFeeScheduleKey)
            .sign(newMetadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfo.freezeKey, .single(newFreezeKey.publicKey))
        XCTAssertEqual(tokenInfo.wipeKey, .single(newWipeKey.publicKey))
        XCTAssertEqual(tokenInfo.kycKey, .single(newKycKey.publicKey))
        XCTAssertEqual(tokenInfo.supplyKey, .single(newSupplyKey.publicKey))
        XCTAssertEqual(tokenInfo.pauseKey, .single(newPauseKey.publicKey))
        XCTAssertEqual(tokenInfo.feeScheduleKey, .single(newFeeScheduleKey.publicKey))
        XCTAssertEqual(tokenInfo.metadataKey, .single(newMetadataKey.publicKey))
    }

    internal func test_UpdateToEmptyKeyListWithDifferentKeySignAndNoValidationFails() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .adminKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Cannot make a token immutable when updating keys to an unusable key (i.e. all-zeros key),
    // signing with a key that is different from an Admin Key, and setting the key verification mode to NO_VALIDATION
    internal func test_UpdateToUnusableKeyWithDifferentKeySigAndNoValidationFails() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey
        )

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .adminKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_UpdateAdminKeytoUnusableKeyAndNoValidationFail() async throws {
        let testEnv: IntegrationTestEnvironment = testEnv

        // Admin and Supply keys.
        let adminKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey
        )

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .adminKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(adminKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_UpdateLowerPrivilegeKeysToUnusableKeyAndNoValidation() async throws {
        // Given
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
        )

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // When / Then
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .freezeKey(.single(unusableKey))
            .wipeKey(.single(unusableKey))
            .kycKey(.single(unusableKey))
            .supplyKey(.single(unusableKey))
            .pauseKey(.single(unusableKey))
            .feeScheduleKey(.single(unusableKey))
            .metadataKey(.single(unusableKey))
            .keyVerificationMode(TokenKeyValidation.noValidation)
            .freezeWith(testEnv.client)
            .sign(freezeKey)
            .sign(wipeKey)
            .sign(kycKey)
            .sign(supplyKey)
            .sign(pauseKey)
            .sign(feeScheduleKey)
            .sign(metadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfo.freezeKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.wipeKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.kycKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.supplyKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.pauseKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.feeScheduleKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.metadataKey, .single(unusableKey))
    }

    internal func test_UpdateLowerPrivilegeKeysWithFullValidation() async throws {
        // Given
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let newFreezeKey = PrivateKey.generateEd25519()
        let newWipeKey = PrivateKey.generateEd25519()
        let newSupplyKey = PrivateKey.generateEd25519()
        let newPauseKey = PrivateKey.generateEd25519()
        let newKycKey = PrivateKey.generateEd25519()
        let newFeeScheduleKey = PrivateKey.generateEd25519()
        let newMetadataKey = PrivateKey.generateEd25519()

        // Create the NFT with all of token's lower-privilege keys.
        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
        )

        // When
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .freezeKey(.single(newFreezeKey.publicKey))
            .wipeKey(.single(newWipeKey.publicKey))
            .kycKey(.single(newKycKey.publicKey))
            .supplyKey(.single(newSupplyKey.publicKey))
            .pauseKey(.single(newPauseKey.publicKey))
            .feeScheduleKey(.single(newFeeScheduleKey.publicKey))
            .metadataKey(.single(newMetadataKey.publicKey))
            .keyVerificationMode(TokenKeyValidation.fullValidation)
            .freezeWith(testEnv.client)
            .sign(freezeKey)
            .sign(wipeKey)
            .sign(kycKey)
            .sign(supplyKey)
            .sign(pauseKey)
            .sign(feeScheduleKey)
            .sign(metadataKey)
            .sign(newFreezeKey)
            .sign(newWipeKey)
            .sign(newKycKey)
            .sign(newSupplyKey)
            .sign(newPauseKey)
            .sign(newFeeScheduleKey)
            .sign(newMetadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfo.freezeKey, .single(newFreezeKey.publicKey))
        XCTAssertEqual(tokenInfo.wipeKey, .single(newWipeKey.publicKey))
        XCTAssertEqual(tokenInfo.kycKey, .single(newKycKey.publicKey))
        XCTAssertEqual(tokenInfo.supplyKey, .single(newSupplyKey.publicKey))
        XCTAssertEqual(tokenInfo.pauseKey, .single(newPauseKey.publicKey))
        XCTAssertEqual(tokenInfo.feeScheduleKey, .single(newFeeScheduleKey.publicKey))
        XCTAssertEqual(tokenInfo.metadataKey, .single(newMetadataKey.publicKey))
    }

    internal func test_UpdateLowerPrivilegeKeysWithOldKeysAndNoValidation() async throws {
        // Given
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let newFreezeKey = PrivateKey.generateEd25519()
        let newWipeKey = PrivateKey.generateEd25519()
        let newSupplyKey = PrivateKey.generateEd25519()
        let newPauseKey = PrivateKey.generateEd25519()
        let newKycKey = PrivateKey.generateEd25519()
        let newFeeScheduleKey = PrivateKey.generateEd25519()
        let newMetadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
        )

        // When
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .freezeKey(.single(newFreezeKey.publicKey))
            .wipeKey(.single(newWipeKey.publicKey))
            .kycKey(.single(newKycKey.publicKey))
            .supplyKey(.single(newSupplyKey.publicKey))
            .pauseKey(.single(newPauseKey.publicKey))
            .feeScheduleKey(.single(newFeeScheduleKey.publicKey))
            .metadataKey(.single(newMetadataKey.publicKey))
            .keyVerificationMode(TokenKeyValidation.noValidation)
            .freezeWith(testEnv.client)
            .sign(freezeKey)
            .sign(wipeKey)
            .sign(kycKey)
            .sign(supplyKey)
            .sign(pauseKey)
            .sign(feeScheduleKey)
            .sign(metadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfo.freezeKey, .single(newFreezeKey.publicKey))
        XCTAssertEqual(tokenInfo.wipeKey, .single(newWipeKey.publicKey))
        XCTAssertEqual(tokenInfo.kycKey, .single(newKycKey.publicKey))
        XCTAssertEqual(tokenInfo.supplyKey, .single(newSupplyKey.publicKey))
        XCTAssertEqual(tokenInfo.pauseKey, .single(newPauseKey.publicKey))
        XCTAssertEqual(tokenInfo.feeScheduleKey, .single(newFeeScheduleKey.publicKey))
        XCTAssertEqual(tokenInfo.metadataKey, .single(newMetadataKey.publicKey))
    }

    internal func test_RemoveLowerPrivilegeKeysWithOldKeysSigAndNoValidationFails() async throws {
        // Given
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(wipeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenIsImmutable
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(freezeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenIsImmutable
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(pauseKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenIsImmutable
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(kycKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenIsImmutable
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(supplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenIsImmutable
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(feeScheduleKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenIsImmutable
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.keyList(KeyList()))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(metadataKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .tokenIsImmutable
        )
    }

    internal func test_UpdateLowerPrivilegeKeysToUnusableKeyWithDifferentKeySigAndNoValidationFails() async throws {
        // Given
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
        )

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_UpdateLowerPrivilegeKeysToUnusableKeyWithOldKeySigAndFullValidationFails() async throws {
        // Given
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
        )

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(wipeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(freezeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(pauseKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(kycKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(supplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(feeScheduleKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(metadataKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_UpdateToUnusableKeyWithOldAndNewKeysAndFullValidationFails() async throws {
        // Given
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let newFreezeKey = PrivateKey.generateEd25519()
        let newWipeKey = PrivateKey.generateEd25519()
        let newSupplyKey = PrivateKey.generateEd25519()
        let newPauseKey = PrivateKey.generateEd25519()
        let newKycKey = PrivateKey.generateEd25519()
        let newFeeScheduleKey = PrivateKey.generateEd25519()
        let newMetadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
        )

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(wipeKey)
                .sign(newWipeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(freezeKey)
                .sign(newFreezeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(pauseKey)
                .sign(newPauseKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(kycKey)
                .sign(newKycKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(supplyKey)
                .sign(newSupplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(feeScheduleKey)
                .sign(newFeeScheduleKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(metadataKey)
                .sign(newMetadataKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    internal func test_UpdateLowerPrivilegeKeysWithOldKeysSigAndFullValidationFails() async throws {
        // Given
        let freezeKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let pauseKey = PrivateKey.generateEd25519()
        let kycKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()

        let newFreezeKey = PrivateKey.generateEd25519()
        let newWipeKey = PrivateKey.generateEd25519()
        let newSupplyKey = PrivateKey.generateEd25519()
        let newPauseKey = PrivateKey.generateEd25519()
        let newKycKey = PrivateKey.generateEd25519()
        let newFeeScheduleKey = PrivateKey.generateEd25519()
        let newMetadataKey = PrivateKey.generateEd25519()

        let tokenId = try await createUnmanagedToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(TokenType.nonFungibleUnique)
                .expirationTime(.now + .minutes(5))
                .treasuryAccountId(testEnv.operator.accountId)
                .freezeKey(.single(freezeKey.publicKey))
                .wipeKey(.single(wipeKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .pauseKey(.single(pauseKey.publicKey))
                .kycKey(.single(kycKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
        )

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.single(newWipeKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(wipeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.single(newFreezeKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(freezeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.single(newPauseKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(pauseKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.single(newKycKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(kycKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.single(newSupplyKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(supplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.single(newFeeScheduleKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(feeScheduleKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )

        await assertReceiptStatus(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.single(newMetadataKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(metadataKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }
}
