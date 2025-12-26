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
}
