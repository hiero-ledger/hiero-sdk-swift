// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class HookStoreTransactionIntegrationTests: HieroIntegrationTestCase {

    internal func test_CanUpdateStorageSlotsWithValidSignatures() async throws {
        // Given
        let hookContractId = try await createEvmHookContract()
        let hookDetails = createHookDetails(contractId: hookContractId)
        let (accountId, accountKey) = try await createAccountWithHook(
            hookDetails: hookDetails,
            initialBalance: Hbar(1)
        )

        let hookEntityId = HookEntityId(accountId: accountId)
        let hookId = HookId(entityId: hookEntityId, hookId: 1)

        var storageSlot = EvmHookStorageSlot()
        storageSlot.key(Data([0x01]))
        storageSlot.value(Data([0x02]))

        var storageUpdate = EvmHookStorageUpdate()
        storageUpdate.setStorageSlot(storageSlot)

        // When / Then
        do {
            _ = try await HookStoreTransaction()
                .hookId(hookId)
                .addStorageUpdate(storageUpdate)
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
            await registerAccountHookStorageKey(accountId, hookId: 1, key: Data([0x01]))
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CannotUpdateStorageWithoutProperSignatures() async throws {
        // Given
        let hookContractId = try await createEvmHookContract()
        let hookDetails = createHookDetails(contractId: hookContractId)
        let (accountId, _) = try await createAccountWithHook(
            hookDetails: hookDetails,
            initialBalance: Hbar(1)
        )

        let hookEntityId = HookEntityId(accountId: accountId)
        let hookId = HookId(entityId: hookEntityId, hookId: 1)

        var storageSlot = EvmHookStorageSlot()
        storageSlot.key(Data([0x01]))
        storageSlot.value(Data([0x02]))

        var storageUpdate = EvmHookStorageUpdate()
        storageUpdate.setStorageSlot(storageSlot)

        // When / Then - execute without signing with account key
        await assertReceiptStatus(
            try await HookStoreTransaction()
                .hookId(hookId)
                .addStorageUpdate(storageUpdate)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_CannotUpdateStorageWithNonExistentHookId() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount(initialBalance: Hbar(1))

        let hookEntityId = HookEntityId(accountId: accountId)
        let hookId = HookId(entityId: hookEntityId, hookId: 999)

        var storageSlot = EvmHookStorageSlot()
        storageSlot.key(Data([0x01]))
        storageSlot.value(Data([0x02]))

        var storageUpdate = EvmHookStorageUpdate()
        storageUpdate.setStorageSlot(storageSlot)

        // When / Then
        await assertReceiptStatus(
            try await HookStoreTransaction()
                .hookId(hookId)
                .addStorageUpdate(storageUpdate)
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .hookNotFound
        )
    }
}
