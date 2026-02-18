// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class AccountUpdateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_SetKey() async throws {
        // Given
        let (accountId, key1) = try await createSimpleUnmanagedAccount()
        let key2 = PrivateKey.generateEd25519()

        // When
        _ = try await AccountUpdateTransaction()
            .accountId(accountId)
            .key(.single(key2.publicKey))
            .sign(key1)
            .sign(key2)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        await registerAccount(accountId, key: key2)

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfo(info, accountId: accountId, key: .single(key2.publicKey))
    }

    internal func test_MissingAccountIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await AccountUpdateTransaction().execute(testEnv.client),
            .accountIDDoesNotExist
        )
    }

    internal func test_UpdateTokenMaxAssociationToLowerValueFails() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .maxAutomaticTokenAssociations(1),
            key: accountKey
        )

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .initialSupply(100_000)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -TestConstants.testTransferAmount)
            .tokenTransfer(tokenId, accountId, TestConstants.testTransferAmount)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .maxAutomaticTokenAssociations(TestConstants.testNoTokenAssociations)
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .existingAutomaticAssociationsExceedGivenLimit
        )
    }

    internal func test_CanAddHookToCreateToAccount() async throws {
        // Given
        let (accountId, key) = try await createTestAccount()
        let fakeContractId = ContractId(shard: 1, realm: 2, num: 3)
        let hookDetails = createHookDetails(contractId: fakeContractId)

        // When / Then
        do {
            _ = try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToCreate(hookDetails)
                .freezeWith(testEnv.client)
                .sign(key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CannotUpdateWithMultipleOfSameHook() async throws {
        // Given
        let (accountId, key) = try await createTestAccount()
        let fakeContractId = ContractId(shard: 1, realm: 2, num: 3)
        let hookDetails = createHookDetails(contractId: fakeContractId)

        // When / Then
        await assertPrecheckStatus(
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToCreate(hookDetails)
                .addHookToCreate(hookDetails)
                .freezeWith(testEnv.client)
                .sign(key)
                .execute(testEnv.client),
            .hookIdRepeatedInCreationDetails
        )
    }

    internal func test_CannotUpdateWithHookAlreadyInUse() async throws {
        // Given
        let (accountId, key) = try await createTestAccount()
        let fakeContractId = ContractId(shard: 1, realm: 2, num: 3)
        let hookDetails = createHookDetails(contractId: fakeContractId)

        // Add hook once
        _ = try await AccountUpdateTransaction()
            .accountId(accountId)
            .addHookToCreate(hookDetails)
            .freezeWith(testEnv.client)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then - Add again should fail
        await assertReceiptStatus(
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToCreate(hookDetails)
                .freezeWith(testEnv.client)
                .sign(key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .hookIdInUse
        )
    }

    internal func test_CanAddHookToCreateToAccountWithStorageUpdates() async throws {
        // Given
        let (accountId, key) = try await createTestAccount()
        let fakeContractId = ContractId(shard: 1, realm: 2, num: 3)
        let hookDetails = createHookDetailsWithStorage(contractId: fakeContractId)

        // When / Then
        do {
            _ = try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToCreate(hookDetails)
                .freezeWith(testEnv.client)
                .sign(key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CanDeleteHook() async throws {
        // Given
        let (accountId, key) = try await createTestAccount()
        let fakeContractId = ContractId(shard: 1, realm: 2, num: 3)
        let hookId: Int64 = 1
        let hookDetails = createHookDetails(contractId: fakeContractId, hookId: hookId)

        // Add hook first
        _ = try await AccountUpdateTransaction()
            .accountId(accountId)
            .addHookToCreate(hookDetails)
            .freezeWith(testEnv.client)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then - Delete hook
        do {
            _ = try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToDelete(hookId)
                .freezeWith(testEnv.client)
                .sign(key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CannotDeleteNonExistentHook() async throws {
        // Given
        let (accountId, key) = try await createTestAccount()
        let fakeContractId = ContractId(shard: 1, realm: 2, num: 3)
        let hookDetails = createHookDetails(contractId: fakeContractId)

        // Add a hook first
        _ = try await AccountUpdateTransaction()
            .accountId(accountId)
            .addHookToCreate(hookDetails)
            .freezeWith(testEnv.client)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then - Delete non-existent hook
        await assertReceiptStatus(
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToDelete(999)
                .freezeWith(testEnv.client)
                .sign(key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .hookNotFound
        )
    }

    internal func test_CannotAddAndDeleteSameHook() async throws {
        // Given
        let (accountId, key) = try await createTestAccount()
        let fakeContractId = ContractId(shard: 1, realm: 2, num: 3)
        let hookId: Int64 = 1
        let hookDetails = createHookDetails(contractId: fakeContractId, hookId: hookId)

        // When / Then
        await assertReceiptStatus(
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToCreate(hookDetails)
                .addHookToDelete(hookId)
                .freezeWith(testEnv.client)
                .sign(key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .hookNotFound
        )
    }
}
