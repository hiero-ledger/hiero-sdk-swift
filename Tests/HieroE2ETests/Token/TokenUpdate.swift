/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import Hiero
import XCTest

internal final class TokenUpdate: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        _ = try await TokenUpdateTransaction(tokenId: token.id, tokenName: "aaaa", tokenSymbol: "A")
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let info = try await TokenInfoQuery(tokenId: token.id).execute(testEnv.client)

        XCTAssertEqual(info.tokenId, token.id)
        XCTAssertEqual(info.name, "aaaa")
        XCTAssertEqual(info.symbol, "A")
        XCTAssertEqual(info.decimals, 3)
        XCTAssertEqual(info.treasuryAccountId, account.id)
        XCTAssertEqual(info.adminKey, .single(account.key.publicKey))
        XCTAssertEqual(info.freezeKey, .single(account.key.publicKey))
        XCTAssertEqual(info.wipeKey, .single(account.key.publicKey))
        XCTAssertEqual(info.kycKey, .single(account.key.publicKey))
        XCTAssertEqual(info.supplyKey, .single(account.key.publicKey))
        XCTAssertEqual(info.defaultFreezeStatus, false)
        XCTAssertEqual(info.defaultKycStatus, false)

    }

    internal func testImmutableTokenFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        // can't delete the account because the token still exists,
        // can't delete the token because there's no admin key.
        let account = try await Account.create(testEnv)

        let receipt = try await TokenCreateTransaction(
            name: "ffff",
            symbol: "F",
            treasuryAccountId: account.id,
            freezeDefault: false,
            expirationTime: .now + .minutes(5)
        )
        .sign(account.key)
        .execute(testEnv.client)
        .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction(tokenId: tokenId, tokenName: "aaaa", tokenSymbol: "A")
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenIsImmutable)
        }
    }

    internal func testUpdateImmutableTokenMetadata() async throws {
        let testEnv = try TestEnvironment.nonFree

        let initialMetadata = Data([1])
        let updatedMetadata = Data([1, 2])
        let metadataKey = PrivateKey.generateEd25519()

        // Create fungible token with metadata and metadata key.
        // Note: The same flow can be executed with a
        // TokenType.NON_FUNGIBLE_UNIQUE (i.e. HIP-765)
        let tokenId = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .tokenType(TokenType.fungibleCommon)
            .expirationTime(.now + .minutes(5))
            .treasuryAccountId(testEnv.operator.accountId)
            .decimals(3)
            .initialSupply(100000)
            .expirationTime(Timestamp.now + .hours(2))
            .metadata(initialMetadata)
            .metadataKey(.single(metadataKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .tokenId!

        let tokenInfoAfterCreation = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(testEnv.client)

        XCTAssertEqual(tokenInfoAfterCreation.metadata, initialMetadata)
        XCTAssertEqual(tokenInfoAfterCreation.metadataKey, .single(metadataKey.publicKey))

        // Update token's metadata
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .metadata(updatedMetadata)
            .freezeWith(testEnv.client)
            .sign(metadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenInfoAfterMetadataUpdate = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(testEnv.client)

        XCTAssertEqual(tokenInfoAfterMetadataUpdate.metadata, updatedMetadata)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Make a token immutable when updating keys to an empty KeyList, signing with an Admin Key,
    // and setting the key verification mode to NO_VALIDATION
    internal func testUpdateKeysWithAdminSigAndNoValidation() async throws {
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEd25519()

        // Admin, Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys(adminKey)

        // Create the token with all keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        let emptyKeyList = KeyList()

        // Update all lower-privilege keys for token with empty key list,
        // signing with admin key, and verifying with no validation.
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .adminKey(.keyList(emptyKeyList))
            .freezeKey(.keyList(emptyKeyList))
            .wipeKey(.keyList(emptyKeyList))
            .kycKey(.keyList(emptyKeyList))
            .supplyKey(.keyList(emptyKeyList))
            .pauseKey(.keyList(emptyKeyList))
            .feeScheduleKey(.keyList(emptyKeyList))
            .metadataKey(.keyList(emptyKeyList))
            .keyVerificationMode(TokenKeyValidation.noValidation)
            .freezeWith(testEnv.client)
            .sign(keys.adminKey!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertNil(tokenInfo.adminKey)
        XCTAssertNil(tokenInfo.freezeKey)
        XCTAssertNil(tokenInfo.wipeKey)
        XCTAssertNil(tokenInfo.kycKey)
        XCTAssertNil(tokenInfo.supplyKey)
        XCTAssertNil(tokenInfo.pauseKey)
        XCTAssertNil(tokenInfo.feeScheduleKey)
        XCTAssertNil(tokenInfo.metadataKey)

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Can remove all of token’s lower-privilege keys when updating keys to an empty KeyList,
    // signing with an Admin Key, and setting the key verification mode to FULL_VALIDATION
    internal func testRemoveKeysWithAdminSigAndFullValidation() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Admin, Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys(PrivateKey.generateEd25519())

        // Create the token with all keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        let emptyKeyList = KeyList()

        // Update all lower-privilege keys for token with empty key list,
        // signing with admin key, and verifying with full validation.
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .adminKey(.keyList(emptyKeyList))
            .freezeKey(.keyList(emptyKeyList))
            .wipeKey(.keyList(emptyKeyList))
            .kycKey(.keyList(emptyKeyList))
            .supplyKey(.keyList(emptyKeyList))
            .pauseKey(.keyList(emptyKeyList))
            .feeScheduleKey(.keyList(emptyKeyList))
            .metadataKey(.keyList(emptyKeyList))
            .keyVerificationMode(TokenKeyValidation.fullValidation)
            .freezeWith(testEnv.client)
            .sign(keys.adminKey!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertNil(tokenInfo.adminKey)
        XCTAssertNil(tokenInfo.freezeKey)
        XCTAssertNil(tokenInfo.wipeKey)
        XCTAssertNil(tokenInfo.kycKey)
        XCTAssertNil(tokenInfo.supplyKey)
        XCTAssertNil(tokenInfo.pauseKey)
        XCTAssertNil(tokenInfo.feeScheduleKey)
        XCTAssertNil(tokenInfo.metadataKey)

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Can update all of token’s lower-privilege keys to an unusable key (i.e. all-zeros key),
    // when signing with an Admin Key, and setting the key verification mode to FULL_VALIDATION, and then revert previous keys
    internal func testRevertKeysFromUnusableWithAdminSigAndFullValidation() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Admin, Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys(PrivateKey.generateEd25519())

        // Create the token with all keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // Update all lower-privilege keys for token with invalid zeros key,
        // signing with admin key, and verifying with full validation.

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
            .sign(keys.adminKey!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfo.freezeKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.wipeKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.kycKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.supplyKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.pauseKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.feeScheduleKey, .single(unusableKey))

        // Update all lower-privilege keys for token with invalid zeros key,
        // signing with admin key, and verifying with full validation.
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .freezeKey(.single(keys.freezeKey.publicKey))
            .wipeKey(.single(keys.wipeKey.publicKey))
            .kycKey(.single(keys.kycKey.publicKey))
            .supplyKey(.single(keys.supplyKey.publicKey))
            .pauseKey(.single(keys.pauseKey.publicKey))
            .feeScheduleKey(.single(keys.feeScheduleKey.publicKey))
            .metadataKey(.single(keys.metadataKey.publicKey))
            .keyVerificationMode(TokenKeyValidation.noValidation)
            .freezeWith(testEnv.client)
            .sign(keys.adminKey!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenInfoAfterUpdate = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfoAfterUpdate.freezeKey, .single(keys.freezeKey.publicKey))
        XCTAssertEqual(tokenInfoAfterUpdate.wipeKey, .single(keys.wipeKey.publicKey))
        XCTAssertEqual(tokenInfoAfterUpdate.kycKey, .single(keys.kycKey.publicKey))
        XCTAssertEqual(tokenInfoAfterUpdate.supplyKey, .single(keys.supplyKey.publicKey))
        XCTAssertEqual(tokenInfoAfterUpdate.pauseKey, .single(keys.pauseKey.publicKey))
        XCTAssertEqual(tokenInfoAfterUpdate.feeScheduleKey, .single(keys.feeScheduleKey.publicKey))
        XCTAssertEqual(tokenInfoAfterUpdate.metadataKey, .single(keys.metadataKey.publicKey))

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Can update all of token’s lower-privilege keys when signing with an Admin Key
    // and new respective lower-privilege key, and setting key verification mode to FULL_VALIDATION
    internal func testUpdateLowPrivilegeKeysWithAdminSigAndFullValidation() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Admin, Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys(PrivateKey.generateEd25519())

        // New Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let newKeys = generateKeys()

        // Create the NFT with all of token’s lower-privilege keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        // Update all lower-privilege keys for token with new lower-privilege keys,
        // signing with admin key and new lower-privilege keys, and verifying with full validation.
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .freezeKey(.single(newKeys.freezeKey.publicKey))
            .wipeKey(.single(newKeys.wipeKey.publicKey))
            .kycKey(.single(newKeys.kycKey.publicKey))
            .supplyKey(.single(newKeys.supplyKey.publicKey))
            .pauseKey(.single(newKeys.pauseKey.publicKey))
            .feeScheduleKey(.single(newKeys.feeScheduleKey.publicKey))
            .metadataKey(.single(newKeys.metadataKey.publicKey))
            .keyVerificationMode(TokenKeyValidation.fullValidation)
            .freezeWith(testEnv.client)
            .sign(keys.adminKey!)
            .sign(newKeys.freezeKey)
            .sign(newKeys.wipeKey)
            .sign(newKeys.kycKey)
            .sign(newKeys.supplyKey)
            .sign(newKeys.pauseKey)
            .sign(newKeys.feeScheduleKey)
            .sign(newKeys.metadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenInfoAfterNewKeysUpdate = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfoAfterNewKeysUpdate.freezeKey, .single(newKeys.freezeKey.publicKey))
        XCTAssertEqual(tokenInfoAfterNewKeysUpdate.wipeKey, .single(newKeys.wipeKey.publicKey))
        XCTAssertEqual(tokenInfoAfterNewKeysUpdate.kycKey, .single(newKeys.kycKey.publicKey))
        XCTAssertEqual(tokenInfoAfterNewKeysUpdate.supplyKey, .single(newKeys.supplyKey.publicKey))
        XCTAssertEqual(tokenInfoAfterNewKeysUpdate.pauseKey, .single(newKeys.pauseKey.publicKey))
        XCTAssertEqual(tokenInfoAfterNewKeysUpdate.feeScheduleKey, .single(newKeys.feeScheduleKey.publicKey))
        XCTAssertEqual(tokenInfoAfterNewKeysUpdate.metadataKey, .single(newKeys.metadataKey.publicKey))

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Cannot make a token immutable when updating keys to an empty KeyList,
    // signing with a key that is different from an Admin Key, and setting the key verification mode to NO_VALIDATION
    internal func testUpdateToEmptyKeyListWithDifferentKeySignAndNoValidation() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Admin, Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys(PrivateKey.generateEd25519())

        // Create the token with all keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        let emptyKeyList = KeyList()

        // Fails to update the immutable token keys to empty keylist without admin signature (sign implicitly with operator key).
        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .adminKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Cannot make a token immutable when updating keys to an unusable key (i.e. all-zeros key),
    // signing with a key that is different from an Admin Key, and setting the key verification mode to NO_VALIDATION
    internal func testUpdateToUsuableKeyWithDifferentKeySigFailsAndNoValidation() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Admin, Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys(PrivateKey.generateEd25519())

        // Create a token with the all keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // Fails to update the immutable token keys to unusable key without admin signature (sign implicitly with operator key).
        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .adminKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Cannot update the Admin Key to an unusable key (i.e. all-zeros key),
    // signing with an Admin Key, and setting the key verification mode to NO_VALIDATION
    internal func testUpdateAdminKeytoUnusableKeyAndNoValidationFail() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Admin and Supply keys.
        let adminKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()

        let tx = try await TokenCreateTransaction()
            .name("Test NFT")
            .symbol("TNFT")
            .tokenType(TokenType.nonFungibleUnique)
            .expirationTime(.now + .minutes(5))
            .treasuryAccountId(testEnv.operator.accountId)
            .adminKey(.single(adminKey.publicKey))
            .supplyKey(.single(supplyKey.publicKey))
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(tx.tokenId)

        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfo.adminKey, .single(adminKey.publicKey))

        // Generate an unusable key.
        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // Update the Admin Key to an unusable key (i.e., all-zeros key),
        // signing with an Admin Key, and setting the key verification mode to NO_VALIDATION
        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .adminKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(adminKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Can update all of token’s lower-privilege keys to an unusable key (i.e. all-zeros key),
    // when signing with a respective lower-privilege key, and setting the key verification mode to NO_VALIDATION
    internal func testUpdateLowerPrivilegeKeysToUnusableKeyAndNoValidation() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys()

        // Create the NFT with all of token’s lower-privilege keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        // Generate an unusable key.
        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // Update all of token’s lower-privilege keys to an unusable key (i.e., all-zeros key),
        // when signing with a respective lower-privilege key,
        // and setting the key verification mode to NO_VALIDATION
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
            .sign(keys.freezeKey)
            .sign(keys.wipeKey)
            .sign(keys.kycKey)
            .sign(keys.supplyKey)
            .sign(keys.pauseKey)
            .sign(keys.feeScheduleKey)
            .sign(keys.metadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfo.freezeKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.wipeKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.kycKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.supplyKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.pauseKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.feeScheduleKey, .single(unusableKey))
        XCTAssertEqual(tokenInfo.metadataKey, .single(unusableKey))

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Can update all of token’s lower-privilege keys when signing with an old lower-privilege key
    // and with a new lower-privilege key, and setting key verification mode to FULL_VALIDATION
    internal func testUpdateLowerPrivilegeKeysWithFullValidation() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys()

        // New Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let newKeys = generateKeys()

        // Create the NFT with all of token’s lower-privilege keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        // Update all of token’s lower-privilege keys when signing with an old respective lower-privilege key,
        // and setting key verification mode to NO_VALIDATION
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .freezeKey(.single(newKeys.freezeKey.publicKey))
            .wipeKey(.single(newKeys.wipeKey.publicKey))
            .kycKey(.single(newKeys.kycKey.publicKey))
            .supplyKey(.single(newKeys.supplyKey.publicKey))
            .pauseKey(.single(newKeys.pauseKey.publicKey))
            .feeScheduleKey(.single(newKeys.feeScheduleKey.publicKey))
            .metadataKey(.single(newKeys.metadataKey.publicKey))
            .keyVerificationMode(TokenKeyValidation.fullValidation)
            .freezeWith(testEnv.client)
            .sign(keys.freezeKey)
            .sign(keys.wipeKey)
            .sign(keys.kycKey)
            .sign(keys.supplyKey)
            .sign(keys.pauseKey)
            .sign(keys.feeScheduleKey)
            .sign(keys.metadataKey)
            .sign(newKeys.freezeKey)
            .sign(newKeys.wipeKey)
            .sign(newKeys.kycKey)
            .sign(newKeys.supplyKey)
            .sign(newKeys.pauseKey)
            .sign(newKeys.feeScheduleKey)
            .sign(newKeys.metadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfo.freezeKey, .single(newKeys.freezeKey.publicKey))
        XCTAssertEqual(tokenInfo.wipeKey, .single(newKeys.wipeKey.publicKey))
        XCTAssertEqual(tokenInfo.kycKey, .single(newKeys.kycKey.publicKey))
        XCTAssertEqual(tokenInfo.supplyKey, .single(newKeys.supplyKey.publicKey))
        XCTAssertEqual(tokenInfo.pauseKey, .single(newKeys.pauseKey.publicKey))
        XCTAssertEqual(tokenInfo.feeScheduleKey, .single(newKeys.feeScheduleKey.publicKey))
        XCTAssertEqual(tokenInfo.metadataKey, .single(newKeys.metadataKey.publicKey))

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Can update all of token’s lower-privilege keys when signing ONLY with an old lower-privilege key,
    // and setting key verification mode to NO_VALIDATION
    internal func testUpdateLowerPrivilegeKeysWithOldKeysAndNoValidation() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys()

        // New Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let newKeys = generateKeys()

        // Create the NFT with all of token’s lower-privilege keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        // Update all of token’s lower-privilege keys when signing with all older respective lower-privilege keys,
        // and setting key verification mode to NO_VALIDATION
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .freezeKey(.single(newKeys.freezeKey.publicKey))
            .wipeKey(.single(newKeys.wipeKey.publicKey))
            .kycKey(.single(newKeys.kycKey.publicKey))
            .supplyKey(.single(newKeys.supplyKey.publicKey))
            .pauseKey(.single(newKeys.pauseKey.publicKey))
            .feeScheduleKey(.single(newKeys.feeScheduleKey.publicKey))
            .metadataKey(.single(newKeys.metadataKey.publicKey))
            .keyVerificationMode(TokenKeyValidation.noValidation)
            .freezeWith(testEnv.client)
            .sign(keys.freezeKey)
            .sign(keys.wipeKey)
            .sign(keys.kycKey)
            .sign(keys.supplyKey)
            .sign(keys.pauseKey)
            .sign(keys.feeScheduleKey)
            .sign(keys.metadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

        XCTAssertEqual(tokenInfo.freezeKey, .single(newKeys.freezeKey.publicKey))
        XCTAssertEqual(tokenInfo.wipeKey, .single(newKeys.wipeKey.publicKey))
        XCTAssertEqual(tokenInfo.kycKey, .single(newKeys.kycKey.publicKey))
        XCTAssertEqual(tokenInfo.supplyKey, .single(newKeys.supplyKey.publicKey))
        XCTAssertEqual(tokenInfo.pauseKey, .single(newKeys.pauseKey.publicKey))
        XCTAssertEqual(tokenInfo.feeScheduleKey, .single(newKeys.feeScheduleKey.publicKey))
        XCTAssertEqual(tokenInfo.metadataKey, .single(newKeys.metadataKey.publicKey))

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Cannot remove all of token’s lower-privilege keys when updating them to an empty KeyList,
    // signing with a respective lower-privilege key, and setting the key verification mode to NO_VALIDATION
    internal func testRemoveLowerPrivilegeKeysWithOldKeysSigAndNoValidationFails() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys()

        // Create the NFT with all of token’s lower-privilege keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        let emptyKeyList = KeyList()

        // Remove all of token’s lower-privilege keys
        // when updating them to an empty KeyList (trying to remove keys one by one to check all errors),
        // signing with a respective lower-privilege key,
        // and setting the key verification mode to NO_VALIDATION
        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(keys.wipeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenIsImmutable)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(keys.freezeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenIsImmutable)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(keys.pauseKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenIsImmutable)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(keys.kycKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenIsImmutable)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(keys.supplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenIsImmutable)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(keys.feeScheduleKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenIsImmutable)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.keyList(emptyKeyList))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .freezeWith(testEnv.client)
                .sign(keys.metadataKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenIsImmutable)
        }

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Cannot update all of token’s lower-privilege keys to an unusable key (i.e. all-zeros key),
    // when signing with a key that is different from a respective lower-privilege key, and setting
    // the key verification mode to NO_VALIDATION
    func testUpdateToLowPrivilegeKeysUsusableKeyWithDifferentKeySigAndNoValidationFails() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys()

        // Create the NFT with all of token’s lower-privilege keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        // Generate an unusable key.
        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // Update all of token’s lower-privilege keys to an unusable key (i.e., all-zeros key),
        // when signing with a respective lower-privilege key,
        // and setting the key verification mode to NO_VALIDATION
        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.noValidation)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Cannot update all of token’s lower-privilege keys to an unusable key (i.e. all-zeros key),
    // when signing ONLY with an old respective lower-privilege key, and setting the key
    // verification mode to FULL_VALIDATION
    func testUpdateLowerPrivilegeKeysToUnusableKeysAndFullValidationFails() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys()

        // Create the NFT with all of token’s lower-privilege keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // Update all of token’s lower-privilege keys to an unusable key (i.e., all-zeros key)
        // (trying to remove keys one by one to check all errors),
        // signing ONLY with an old respective lower-privilege key,
        // and setting the key verification mode to FULL_VALIDATION
        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.wipeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.freezeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.pauseKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.kycKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.supplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.feeScheduleKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.metadataKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Cannot update all of token’s lower-privilege keys to an unusable key (i.e. all-zeros key),
    // when signing with an old respective lower-privilege key and new respective lower-privilege key,
    // and setting the key verification mode to FULL_VALIDATION
    internal func testUpdateToUnusableKeyWithOldAndNewKeysAndFullValidationFails() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys()

        // New Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let newKeys = generateKeys()

        // Create the NFT with all of token’s lower-privilege keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        // Generate an unusable key.
        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // Update all of token’s lower-privilege keys to an unusable key (i.e., all-zeros key)
        // (trying to remove keys one by one to check all errors),
        // signing with an old respective lower-privilege key and new respective lower-privilege key,
        // and setting the key verification mode to FULL_VALIDATION
        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.wipeKey)
                .sign(newKeys.wipeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.freezeKey)
                .sign(newKeys.freezeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.pauseKey)
                .sign(newKeys.pauseKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.kycKey)
                .sign(newKeys.kycKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.supplyKey)
                .sign(newKeys.supplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.feeScheduleKey)
                .sign(newKeys.feeScheduleKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.single(unusableKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.metadataKey)
                .sign(newKeys.metadataKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }

    // HIP-540 (https://hips.hedera.com/hip/hip-540)
    // Cannot update all of token’s lower-privilege keys, when signing ONLY with an
    // old respective lower-privilege key, and setting the key verification mode to
    // FULL_VALIDATION
    internal func testUpdateToNewKeysWithOldKeysSigAndFullValidation() async throws {
        let testEnv: NonfreeTestEnvironment = try TestEnvironment.nonFree

        // Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let keys = generateKeys()

        // New Freeze, Wipe, Kyc, Supply, Pause, Fee Schedule, and Metadata keys.
        let newKeys = generateKeys()

        // Create the NFT with all of token’s lower-privilege keys.
        let tokenId = try await createTokenWithKeys(testEnv, keys)

        // Update all of token’s lower-privilege keys
        // (trying to update keys one by one to check all errors),
        // signing ONLY with an old respective lower-privilege key,
        // and setting the key verification mode to FULL_VALIDATION
        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .wipeKey(.single(newKeys.wipeKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.wipeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .freezeKey(.single(newKeys.freezeKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.freezeKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .pauseKey(.single(newKeys.pauseKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.pauseKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .kycKey(.single(newKeys.kycKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.kycKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .supplyKey(.single(newKeys.supplyKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.supplyKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .feeScheduleKey(.single(newKeys.feeScheduleKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.feeScheduleKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        await assertThrowsHErrorAsync(
            try await TokenUpdateTransaction()
                .tokenId(tokenId)
                .metadataKey(.single(newKeys.metadataKey.publicKey))
                .keyVerificationMode(TokenKeyValidation.fullValidation)
                .freezeWith(testEnv.client)
                .sign(keys.metadataKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(testEnv.client)
    }
}

struct Keys {
    let adminKey: PrivateKey?
    let freezeKey: PrivateKey
    let wipeKey: PrivateKey
    let supplyKey: PrivateKey
    let pauseKey: PrivateKey
    let kycKey: PrivateKey
    let feeScheduleKey: PrivateKey
    let metadataKey: PrivateKey
}

func generateKeys(_ adminKey: PrivateKey? = nil) -> Keys {
    .init(
        adminKey: adminKey, freezeKey: PrivateKey.generateEd25519(), wipeKey: PrivateKey.generateEd25519(),
        supplyKey: PrivateKey.generateEd25519(), pauseKey: PrivateKey.generateEd25519(),
        kycKey: PrivateKey.generateEd25519(), feeScheduleKey: PrivateKey.generateEd25519(),
        metadataKey: PrivateKey.generateEd25519())
}

func createTokenWithKeys(_ testEnv: NonfreeTestEnvironment, _ keys: Keys) async throws -> TokenId {
    let tx = TokenCreateTransaction()
        .name("Test NFT")
        .symbol("TNFT")
        .tokenType(TokenType.nonFungibleUnique)
        .expirationTime(.now + .minutes(5))
        .treasuryAccountId(testEnv.operator.accountId)
        .freezeKey(.single(keys.freezeKey.publicKey))
        .wipeKey(.single(keys.wipeKey.publicKey))
        .supplyKey(.single(keys.supplyKey.publicKey))
        .pauseKey(.single(keys.pauseKey.publicKey))
        .kycKey(.single(keys.kycKey.publicKey))
        .feeScheduleKey(.single(keys.feeScheduleKey.publicKey))
        .metadataKey(.single(keys.metadataKey.publicKey))

    if let adminKey = keys.adminKey {
        try tx.adminKey(.single(adminKey.publicKey)).freezeWith(testEnv.client).sign(adminKey)
    }

    let tokenId = try await tx.execute(testEnv.client).getReceipt(testEnv.client).tokenId!

    let tokenInfo = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)

    if let adminKey = keys.adminKey {
        XCTAssertEqual(tokenInfo.adminKey, .single(adminKey.publicKey))
    } else {
        XCTAssertNil(tokenInfo.adminKey)
    }

    XCTAssertEqual(tokenInfo.freezeKey, .single(keys.freezeKey.publicKey))
    XCTAssertEqual(tokenInfo.wipeKey, .single(keys.wipeKey.publicKey))
    XCTAssertEqual(tokenInfo.supplyKey, .single(keys.supplyKey.publicKey))
    XCTAssertEqual(tokenInfo.pauseKey, .single(keys.pauseKey.publicKey))
    XCTAssertEqual(tokenInfo.kycKey, .single(keys.kycKey.publicKey))
    XCTAssertEqual(tokenInfo.feeScheduleKey, .single(keys.feeScheduleKey.publicKey))
    XCTAssertEqual(tokenInfo.metadataKey, .single(keys.metadataKey.publicKey))

    return tokenId
}
