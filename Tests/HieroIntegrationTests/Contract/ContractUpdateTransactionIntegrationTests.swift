// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ContractUpdateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let contractId = try await createStandardContract()

        // When
        _ = try await ContractUpdateTransaction(contractId: contractId, contractMemo: "[swift::e2e::ContractUpdate]")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)
        assertStandardContractInfo(
            info,
            contractId: contractId,
            adminKey: .single(testEnv.operator.privateKey.publicKey)
        )
        XCTAssertEqual(info.contractMemo, "[swift::e2e::ContractUpdate]")
    }

    internal func test_MissingContractIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await ContractUpdateTransaction(contractMemo: "[swift::e2e::ContractUpdate]")
                .execute(testEnv.client),
            .invalidContractID
        )
    }

    internal func test_ImmutableContractFails() async throws {
        // Given
        let contractId = try await createImmutableContract()

        // When / Then
        await assertReceiptStatus(
            try await ContractUpdateTransaction(contractId: contractId, contractMemo: "[swift::e2e::ContractUpdate]")
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .modifyingImmutableContract
        )
    }

    internal func test_CanAddHookToContract() async throws {
        // Given
        let contractId = try await createStandardContract()
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookDetails = createHookDetails(contractId: lambdaContractId)

        // When / Then
        do {
            _ = try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToCreate(hookDetails)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CannotAddDuplicateHooksToContract() async throws {
        // Given
        let contractId = try await createStandardContract()
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookDetails = createHookDetails(contractId: lambdaContractId)

        // When / Then
        await assertPrecheckStatus(
            try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToCreate(hookDetails)
                .addHookToCreate(hookDetails)
                .execute(testEnv.client),
            .hookIdRepeatedInCreationDetails
        )
    }

    internal func test_CannotAddHookToContractThatAlreadyExists() async throws {
        // Given
        let contractId = try await createStandardContract()
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookDetails = createHookDetails(contractId: lambdaContractId)

        // Add hook first
        _ = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToCreate(hookDetails)
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then - Adding same hook again should fail
        await assertReceiptStatus(
            try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToCreate(hookDetails)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .hookIdInUse
        )
    }

    internal func test_CanAddHookToContractWithStorageUpdates() async throws {
        // Given
        let contractId = try await createStandardContract()
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookDetails = createHookDetailsWithStorage(contractId: lambdaContractId)

        // When / Then
        do {
            _ = try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToCreate(hookDetails)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CanDeleteHookFromContract() async throws {
        // Given
        let contractId = try await createStandardContract()
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookId: Int64 = 1
        let hookDetails = createHookDetails(contractId: lambdaContractId, hookId: hookId)

        // Add hook first
        _ = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToCreate(hookDetails)
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then - Delete hook
        do {
            _ = try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToDelete(hookId)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CannotDeleteNonExistentHookFromContract() async throws {
        // Given
        let contractId = try await createStandardContract()
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookDetails = createHookDetails(contractId: lambdaContractId)

        // Add a hook first
        _ = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToCreate(hookDetails)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then - Delete non-existent hook
        await assertReceiptStatus(
            try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToDelete(999)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .hookNotFound
        )
    }

    internal func test_CannotAddAndDeleteSameHookFromContract() async throws {
        // Given
        let contractId = try await createStandardContract()
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookId: Int64 = 1
        let hookDetails = createHookDetails(contractId: lambdaContractId, hookId: hookId)

        // When / Then
        await assertReceiptStatus(
            try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToCreate(hookDetails)
                .addHookToDelete(hookId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .hookNotFound
        )
    }

    internal func test_CannotDeleteAlreadyDeletedHookFromContract() async throws {
        // Given
        let contractId = try await createStandardContract()
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookId: Int64 = 1
        let hookDetails = createHookDetails(contractId: lambdaContractId, hookId: hookId)

        // Add hook
        _ = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToCreate(hookDetails)
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Delete hook once
        _ = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToDelete(hookId)
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToDelete(hookId)
                .freezeWith(testEnv.client)
                .sign(testEnv.operator.privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .hookNotFound
        )
    }
}
