// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ContractCreateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given / When
        let contractId = try await createStandardContract()

        // Then
        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)
        assertStandardContractInfo(
            info,
            contractId: contractId,
            adminKey: .single(testEnv.operator.privateKey.publicKey)
        )
    }

    internal func test_NoAdminKey() async throws {
        // Given / When
        let contractId = try await createImmutableContract()

        // Then
        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)
        assertImmutableContractInfo(info, contractId: contractId)
    }

    internal func test_UnsetGasFails() async throws {
        // Given
        let fileId = try await createContractBytecodeFile()

        // When / Then
        await assertPrecheckStatus(
            try await ContractCreateTransaction()
                .constructorParameters(TestConstants.standardContractConstructorParameters())
                .bytecodeFileId(fileId)
                .execute(testEnv.client),
            .insufficientGas
        )
    }

    internal func test_ConstructorParametersUnsetFails() async throws {
        // Given
        let fileId = try await createContractBytecodeFile()

        // When / Then
        await assertReceiptStatus(
            try await ContractCreateTransaction()
                .gas(TestConstants.standardContractGas)
                .bytecodeFileId(fileId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .contractRevertExecuted
        )
    }

    internal func test_BytecodeFileIdUnsetFails() async throws {
        // Given / When / Then
        await assertReceiptStatus(
            try await ContractCreateTransaction()
                .gas(TestConstants.standardContractGas)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidFileID
        )
    }

    internal func test_CreateContractWithHook() async throws {
        // Given
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookDetails = createHookDetails(contractId: lambdaContractId)

        // When
        let txReceipt = try await ContractCreateTransaction()
            .bytecode(TestConstants.evmHookBytecode)
            .gas(300_000)
            .addHook(hookDetails)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertNotNil(txReceipt.contractId)
    }

    internal func test_CreateContractWithHookWithStorageUpdates() async throws {
        // Given
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookDetails = createHookDetailsWithStorage(contractId: lambdaContractId)

        // When
        let txReceipt = try await ContractCreateTransaction()
            .bytecode(TestConstants.evmHookBytecode)
            .gas(300_000)
            .addHook(hookDetails)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertNotNil(txReceipt.contractId)
    }

    internal func test_CannotCreateContractWithNoContractIdForHook() async throws {
        // Given - Hook with no contract ID (invalid)
        let lambdaEvmHook = LambdaEvmHook()
        let hookDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        // When / Then
        await assertReceiptStatus(
            try await ContractCreateTransaction()
                .bytecode(TestConstants.evmHookBytecode)
                .gas(300_000)
                .addHook(hookDetails)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidHookCreationSpec
        )
    }

    internal func test_CannotCreateContractWithDuplicateHookId() async throws {
        // Given
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookDetails = createHookDetails(contractId: lambdaContractId)

        // When / Then
        await assertPrecheckStatus(
            try await ContractCreateTransaction()
                .bytecode(TestConstants.evmHookBytecode)
                .gas(300_000)
                .addHook(hookDetails)
                .addHook(hookDetails)
                .execute(testEnv.client),
            .hookIdRepeatedInCreationDetails
        )
    }

    internal func test_CreateContractWithHookWithAdminKey() async throws {
        // Given
        let adminKey = PrivateKey.generateEcdsa()
        let lambdaContractId = try await createUnmanagedEvmHookContract()
        let hookDetails = createHookDetails(
            contractId: lambdaContractId,
            adminKey: .single(adminKey.publicKey)
        )

        // When
        let txReceipt = try await ContractCreateTransaction()
            .bytecode(TestConstants.evmHookBytecode)
            .gas(300_000)
            .addHook(hookDetails)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertNotNil(txReceipt.contractId)
    }
}
