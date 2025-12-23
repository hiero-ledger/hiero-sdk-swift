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
        let privateKey = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock {
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(privateKey)
                .execute(testEnv.client)
        }

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = ContractId(shard: 1, realm: 2, num: 3)

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        // When / Then
        do {
            _ = try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToCreate(hookCreationDetails)
                .freezeWith(testEnv.client)
                .sign(privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CannotUpdateWithMultipleOfSameHook() async throws {
        // Given
        let privateKey = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock {
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(privateKey)
                .execute(testEnv.client)
        }

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = ContractId(shard: 1, realm: 2, num: 3)

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        await assertThrowsHErrorAsync(
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToCreate(hookCreationDetails)
                .addHookToCreate(hookCreationDetails)
                .freezeWith(testEnv.client)
                .sign(privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("Expected `.transactionPreCheckStatus`, got \(error.kind)")
                return
            }
            XCTAssertEqual(status, .hookIdRepeatedInCreationDetails)
        }
    }

    internal func test_CannotUpdateWithHookAlreadyInUse() async throws {

        // Given
        let privateKey = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock {
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(privateKey)
                .execute(testEnv.client)
        }

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = ContractId(shard: 1, realm: 2, num: 3)

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        // Add once
        _ = try await AccountUpdateTransaction()
            .accountId(accountId)
            .addHookToCreate(hookCreationDetails)
            .freezeWith(testEnv.client)
            .sign(privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Add again should fail
        await assertThrowsHErrorAsync(
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToCreate(hookCreationDetails)
                .freezeWith(testEnv.client)
                .sign(privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("Expected `.receiptStatus`, got \(error.kind)")
                return
            }
            XCTAssertEqual(status, .hookIdInUse)
        }
    }

    internal func test_CanAddHookToCreateToAccountWithStorageUpdates() async throws {

        // Given
        let privateKey = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock {
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(privateKey)
                .execute(testEnv.client)
        }

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = ContractId(shard: 1, realm: 2, num: 3)

        var slot = LambdaStorageSlot()
        slot.key = Data([0x01, 0x23, 0x45])
        slot.value = Data([0x67, 0x89, 0xAB])

        var update = LambdaStorageUpdate()
        update.storageSlot = slot

        lambdaEvmHook.addStorageUpdate(update)

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        // When / Then
        do {
            _ = try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToCreate(hookCreationDetails)
                .freezeWith(testEnv.client)
                .sign(privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CanDeleteHook() async throws {

        // Given
        let privateKey = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock {
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(privateKey)
                .execute(testEnv.client)
        }

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = ContractId(shard: 1, realm: 2, num: 3)

        let hookId: Int64 = 1
        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: hookId,
            lambdaEvmHook: lambdaEvmHook
        )

        // Add
        _ = try await AccountUpdateTransaction()
            .accountId(accountId)
            .addHookToCreate(hookCreationDetails)
            .freezeWith(testEnv.client)
            .sign(privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Delete
        do {
            _ = try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToDelete(hookId)
                .freezeWith(testEnv.client)
                .sign(privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CannotDeleteNonExistentHook() async throws {

        // Given
        let privateKey = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock {
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(privateKey)
                .execute(testEnv.client)
        }

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = ContractId(shard: 1, realm: 2, num: 3)

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        // Add
        _ = try await AccountUpdateTransaction()
            .accountId(accountId)
            .addHookToCreate(hookCreationDetails)
            .freezeWith(testEnv.client)
            .sign(privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Delete non-existent hook
        await assertThrowsHErrorAsync(
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToDelete(999)
                .freezeWith(testEnv.client)
                .sign(privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("Expected `.receiptStatus`, got \(error.kind)")
                return
            }
            XCTAssertEqual(status, .hookNotFound)
        }
    }

    internal func test_CannotAddAndDeleteSameHook() async throws {

        // Given
        let privateKey = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock {
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(privateKey)
                .execute(testEnv.client)
        }

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = ContractId(shard: 1, realm: 2, num: 3)

        let hookId: Int64 = 1
        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: hookId,
            lambdaEvmHook: lambdaEvmHook
        )

        await assertThrowsHErrorAsync(
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .addHookToCreate(hookCreationDetails)
                .addHookToDelete(hookId)
                .freezeWith(testEnv.client)
                .sign(privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("Expected `.receiptStatus`, got \(error.kind)")
                return
            }
            XCTAssertEqual(status, .hookNotFound)
        }
    }
}
