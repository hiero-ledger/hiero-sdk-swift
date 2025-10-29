// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class AccountUpdate: XCTestCase {
    internal func testSetKey() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()

        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key1.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock {
            // need a teardown block that signs with both keys because we don't know when this block is executed.
            // it could be executed right now, or after the update succeeds.
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(key1)
                .sign(key2)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        do {
            let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

            XCTAssertEqual(info.key, .single(key1.publicKey))

            _ = try await AccountUpdateTransaction()
                .accountId(accountId)
                .key(.single(key2.publicKey))
                .sign(key1)
                .sign(key2)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.key, .single(key2.publicKey))
        XCTAssertEqual(info.balance, 0)
        XCTAssertEqual(info.autoRenewPeriod, .days(90))
        // fixme: ensure no warning gets emitted.
        // XCTAssertNil(info.proxyAccountId)
        XCTAssertEqual(info.proxyReceived, 0)

    }

    internal func testMissingAccountIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await AccountUpdateTransaction().execute(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .accountIDDoesNotExist)
        }
    }

    internal func testCannotUpdateTokenMaxAssociationToLowerValueFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let accountKey = PrivateKey.generateEd25519()

        // Create account with max token associations of 1
        let accountCreateReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey.publicKey))
            .maxAutomaticTokenAssociations(1)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(accountCreateReceipt.accountId)

        // Create token
        let tokenCreateReceipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .initialSupply(100_000)
            .treasuryAccountId(testEnv.operator.accountId)
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(tokenCreateReceipt.tokenId)

        // Associate token with account
        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -10)
            .tokenTransfer(tokenId, accountId, 10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            // Update account max token associations to 0
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .maxAutomaticTokenAssociations(0)
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .existingAutomaticAssociationsExceedGivenLimit)
        }
    }

    internal func test_CanAddHookToCreateToAccount() async throws {
        let testEnv = try TestEnvironment.nonFree

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
        let testEnv = try TestEnvironment.nonFree

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
        let testEnv = try TestEnvironment.nonFree

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
        let testEnv = try TestEnvironment.nonFree

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
        let testEnv = try TestEnvironment.nonFree

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
        let testEnv = try TestEnvironment.nonFree

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
        let testEnv = try TestEnvironment.nonFree

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
