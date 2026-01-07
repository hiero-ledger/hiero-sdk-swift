// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ContractBytecodeQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_Query() async throws {
        // Given
        let contractId = try await createStandardContract()

        // When
        let bytecode = try await ContractBytecodeQuery()
            .contractId(contractId)
            .execute(testEnv.client)

        // Then
        XCTAssertEqual(bytecode.count, 798)
    }

    internal func test_GetCostBigMaxQuery() async throws {
        // Given
        let contractId = try await createStandardContract()
        let bytecodeQuery = ContractBytecodeQuery()
            .contractId(contractId)
            .maxPaymentAmount(Hbar(1000))
        let cost = try await bytecodeQuery.getCost(testEnv.client)

        // When
        let bytecode = try await bytecodeQuery.paymentAmount(cost).execute(testEnv.client)

        // Then
        XCTAssertEqual(bytecode.count, 798)
    }

    internal func test_GetCostSmallMaxQuery() async throws {
        // Given
        let contractId = try await createStandardContract()
        let bytecodeQuery = ContractBytecodeQuery()
            .contractId(contractId)
            .maxPaymentAmount(Hbar.fromTinybars(1))
        let cost = try await bytecodeQuery.getCost(testEnv.client)

        // When / Then
        await assertMaxQueryPaymentExceeded(
            try await bytecodeQuery.execute(testEnv.client),
            queryCost: cost,
            maxQueryPayment: .fromTinybars(1)
        )
    }
}
