// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ContractExecuteTransactionIntegrationTests: HieroIntegrationTestCase {

    internal func test_Basic() async throws {
        // Given
        let contractId = try await createStandardContract()

        // When / Then
        _ = try await ContractExecuteTransaction(contractId: contractId, gas: TestConstants.contractExecuteGas)
            .function("setMessage", ContractFunctionParameters().addString("new message"))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_MissingContractIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await ContractExecuteTransaction(gas: TestConstants.contractExecuteGas)
                .function("setMessage", ContractFunctionParameters().addString("new message"))
                .execute(testEnv.client),
            .invalidContractID
        )
    }

    internal func test_MissingFunctionParametersFails() async throws {
        // Given
        let contractId = try await createStandardContract()

        // When / Then
        await assertReceiptStatus(
            try await ContractExecuteTransaction(contractId: contractId, gas: TestConstants.contractExecuteGas)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .contractRevertExecuted
        )
    }

    internal func test_MissingGasFails() async throws {
        // Given
        let contractId = try await createStandardContract()

        // When / Then
        await assertPrecheckStatus(
            try await ContractExecuteTransaction(contractId: contractId)
                .function("setMessage", ContractFunctionParameters().addString("new message"))
                .execute(testEnv.client),
            .insufficientGas
        )
    }
}
