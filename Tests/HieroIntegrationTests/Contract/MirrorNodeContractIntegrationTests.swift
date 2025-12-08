// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class MirrorNodeContractIntegrationTests: HieroIntegrationTestCase {
    internal func disabledTestCanEstimateAndCall() async throws {
        // Given
        let contractId = try await createStandardContract()

        /// Wait 3 seconds for the mirror node to import the contract data.
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // When
        let estimateResponse = try await MirrorNodeContractEstimateGasQuery()
            .contractId(contractId)
            .sender(testEnv.operator.accountId)
            .gasLimit(50_000)
            .gasPrice(1234)
            .function("getMessage")
            .execute(testEnv.client)
        let estimatedGas = try XCTUnwrap(UInt64(estimateResponse, radix: 16))

        let consensusNodeResponse = try await ContractCallQuery()
            .contractId(contractId)
            .gas(estimatedGas)
            .maxPaymentAmount(Hbar(1))
            .function("getMessage")
            .execute(testEnv.client)

        let mirrorNodeResponse = try await MirrorNodeContractCallQuery()
            .contractId(contractId)
            .function("getMessage")
            .execute(testEnv.client)

        // Then
        XCTAssertEqual(consensusNodeResponse.bytes.map { String(format: "%02x", $0) }.joined(), mirrorNodeResponse)
    }

    internal func disabledTestBadContractId() async throws {
        // Given / When
        let estimateResponse = try await MirrorNodeContractEstimateGasQuery()
            .contractId(ContractId(999999))
            .sender(testEnv.operator.accountId)
            .function("getMessage")
            .execute(testEnv.client)
        let estimatedGas = try XCTUnwrap(UInt64(estimateResponse, radix: 16))

        // Then
        XCTAssertEqual(estimatedGas, 22892)
    }

    internal func disabledTestLowGasLimit() async throws {
        // Given
        let contractId = try await createStandardContract()

        /// Wait 3 seconds for the mirror node to import the contract data.
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // When / Then
        await assertThrowsHErrorAsync(
            try await MirrorNodeContractEstimateGasQuery()
                .contractId(contractId)
                .sender(testEnv.operator.accountId)
                .gasLimit(10)
                .gasPrice(1234)
                .function("getMessage")
                .execute(testEnv.client),
            "expected error querying gas estimate"
        ) { error in
            XCTAssertEqual(error.kind, .basicParse)
        }
    }
}
