// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class AccountCreateTransactionIntegrationTests: HieroIntegrationTestCase {

    internal func test_InitialBalanceAndKey() async throws {
        // Given
        let key = PrivateKey.generateEd25519()

        // When
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(key.publicKey))
                .initialBalance(TestConstants.testSmallHbarBalance),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfo(info, accountId: accountId, key: .single(key.publicKey))
        XCTAssertEqual(info.balance, 1)
        XCTAssertEqual(info.autoRenewPeriod, .days(90))
        XCTAssertEqual(info.proxyReceived, 0)
    }

    internal func test_NoInitialBalance() async throws {
        // Given
        let key = PrivateKey.generateEd25519()

        // When
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(key.publicKey)),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfo(info, accountId: accountId, key: .single(key.publicKey))
        XCTAssertEqual(info.balance, 0)
        XCTAssertEqual(info.autoRenewPeriod, .days(90))
        XCTAssertEqual(info.proxyReceived, 0)
    }

    internal func test_MissingKeyFails() async throws {
        await assertPrecheckStatus(
            try await AccountCreateTransaction().execute(testEnv.client),
            .keyRequired
        )
    }

    internal func test_AliasKey() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let aliasId = key.toAccountId(shard: 0, realm: 0)

        // When
        _ = try await TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, "-0.01")
            .hbarTransfer(aliasId, "0.01")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await AccountInfoQuery().accountId(aliasId).execute(testEnv.client)
        await registerAccount(info.accountId, key: key)
        XCTAssertEqual(info.aliasKey, key.publicKey)
    }

    internal func test_AliasFromAdminKey() async throws {
        // Given
        let (adminKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(adminKey.publicKey))
                .alias(evmAddress),
            key: adminKey
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfoWithEvmAddress(
            info, accountId: accountId, key: .single(adminKey.publicKey), evmAddress: evmAddress)
    }

    internal func test_AliasFromAdminKeyWithReceiverSigRequired() async throws {
        // Given
        let (adminKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(adminKey.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .sign(adminKey),
            key: adminKey
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfoWithEvmAddress(
            info, accountId: accountId, key: .single(adminKey.publicKey), evmAddress: evmAddress)
    }

    internal func test_AliasFromAdminKeyWithReceiverSigRequiredMissingSignatureFails()
        async throws
    {
        // Given
        let (adminKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When / Then
        await assertReceiptStatus(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(adminKey.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_Alias() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let (aliasKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .keyWithoutAlias(.single(key.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .sign(aliasKey),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfoWithEvmAddress(info, accountId: accountId, key: .single(key.publicKey), evmAddress: evmAddress)
    }

    internal func test_AliasMissingSignatureFails() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let (_, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When / Then
        await assertReceiptStatus(
            try await AccountCreateTransaction()
                .keyWithoutAlias(.single(key.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_AliasWithReceiverSigRequired() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let (aliasKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(key.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .sign(key)
                .sign(aliasKey),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfoWithEvmAddress(info, accountId: accountId, key: .single(key.publicKey), evmAddress: evmAddress)
    }

    internal func test_AliasWithReceiverSigRequiredMissingSignatureFails() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let (_, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When / Then
        await assertReceiptStatus(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(key.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_AliasWithoutBothKeySignaturesFails() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        _ = try await createAccount(
            try AccountCreateTransaction().keyWithoutAlias(.single(key.publicKey)).freezeWith(testEnv.client), key: key)

        // When / Then
        let aliasKey = PrivateKey.generateEcdsa()
        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithAlias(.single(key.publicKey), aliasKey)
                .freezeWith(testEnv.client)
                .sign(aliasKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating account"
        )
    }

    internal func test_VerifyKeyAndAliasAreFromAliasAccount() async throws {
        // Given
        let (ecdsaKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithAlias(ecdsaKey)
                .freezeWith(testEnv.client)
                .sign(ecdsaKey),
            key: ecdsaKey
        )

        // Then
        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertNotNil(info.accountId)
        XCTAssertEqual(info.key, .single(ecdsaKey.publicKey))
        assertAccountInfoContainsEvmAddress(info, evmAddress: evmAddress)
    }

    internal func test_VerifySetKeyWithEcdsaKeyAndAlias() async throws {
        // Given
        let (ecdsaKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()
        let key = PrivateKey.generateEd25519()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithAlias(.single(key.publicKey), ecdsaKey)
                .freezeWith(testEnv.client)
                .sign(key)
                .sign(ecdsaKey),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertNotNil(info.accountId)
        XCTAssertEqual(info.key, .single(key.publicKey))
        assertAccountInfoContainsEvmAddress(info, evmAddress: evmAddress)
    }

    internal func test_VerifySetKeyWithoutAlias() async throws {
        // Given
        let key = PrivateKey.generateEcdsa()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(key.publicKey))
                .freezeWith(testEnv.client)
                .sign(key),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertNotNil(info.accountId)
        XCTAssertEqual(info.key, .single(key.publicKey))
        XCTAssertTrue(isZeroEvmAddress(try info.contractAccountId.bytes))
    }

    internal func test_SetKeyWithAliasWithEd25519KeyFails() async throws {
        // Given
        let key = PrivateKey.generateEd25519()

        // When / Then
        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithAlias(key)
                .freezeWith(testEnv.client)
                .sign(key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating account"
        )
    }
}
