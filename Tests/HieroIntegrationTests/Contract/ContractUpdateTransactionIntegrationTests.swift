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
}
