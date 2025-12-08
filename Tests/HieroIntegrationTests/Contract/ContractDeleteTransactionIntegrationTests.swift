// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ContractDeleteTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_AdminKey() async throws {
        // Given
        let contractId = try await createUnmanagedContractWithOperatorAdmin()

        // When
        _ = try await ContractDeleteTransaction(contractId: contractId)
            .transferAccountId(testEnv.operator.accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let res = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)
        XCTAssertTrue(res.isDeleted)
    }

    internal func test_MissingAdminKeyFails() async throws {
        // Given
        let contractId = try await createImmutableContract()

        // When / Then
        await assertReceiptStatus(
            try await ContractDeleteTransaction(contractId: contractId)
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .modifyingImmutableContract
        )
    }

    internal func test_MissingContractIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await ContractDeleteTransaction()
                .execute(testEnv.client),
            .invalidContractID
        )
    }
}
