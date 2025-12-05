// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ContractInfoQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_Query() async throws {
        // Given
        let contractId = try await createStandardContract()

        // When
        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)

        // Then
        assertStandardContractInfo(
            info,
            contractId: contractId,
            adminKey: .single(testEnv.operator.privateKey.publicKey)
        )
    }

    internal func test_QueryNoAdminKey() async throws {
        // Given
        let contractId = try await createImmutableContract()

        // When
        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)

        // Then
        assertImmutableContractInfo(info, contractId: contractId)
    }

    internal func test_MissingContractIdFails() async throws {
        // Given / When / Then
        await assertThrowsHErrorAsync(
            try await ContractInfoQuery().execute(testEnv.client)
        ) { error in
            guard case .queryNoPaymentPreCheckStatus(let status) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryNoPaymentPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidContractID)
        }
    }

    internal func test_QueryCostBigMax() async throws {
        // Given
        let contractId = try await createStandardContract()
        let query = ContractInfoQuery(contractId: contractId).maxPaymentAmount(10000)
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        _ = try await query.paymentAmount(cost).execute(testEnv.client)
    }

    internal func test_QueryCostSmallMaxFails() async throws {
        // Given
        let contractId = try await createStandardContract()

        // When
        let query = ContractInfoQuery(contractId: contractId).maxPaymentAmount(.fromTinybars(1))
        let cost = try await query.getCost(testEnv.client)

        // Then
        await assertThrowsHErrorAsync(
            try await query.execute(testEnv.client),
            "expected error querying contract"
        ) { error in
            // note: there's a very small chance this fails if the cost of a ContractInfoQuery changes right when we execute it.
            XCTAssertEqual(error.kind, .maxQueryPaymentExceeded(queryCost: cost, maxQueryPayment: .fromTinybars(1)))
        }
    }

    internal func disabledTestQueryCostInsufficientTxFeeFails() async throws {
        // Given
        let contractId = try await createStandardContract()

        // When / Then
        await assertThrowsHErrorAsync(
            try await ContractInfoQuery(contractId: contractId)
                .maxPaymentAmount(.fromTinybars(10000))
                .paymentAmount(.fromTinybars(1))
                .execute(testEnv.client)
        ) { error in
            guard case .queryPaymentPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryPaymentPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .insufficientTxFee)
        }
    }
}
