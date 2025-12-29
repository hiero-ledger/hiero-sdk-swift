// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ContractNonceInfoIntegrationTests: HieroIntegrationTestCase {
    internal func disabledTestIncrementNonceThroughContractConstructor() async throws {
        // Given
        let fileId = try await createContractBytecodeFile()

        // When
        let contractCreateResponse = try await standardContractCreateTransaction(
            fileId: fileId,
            adminKey: testEnv.operator.privateKey.publicKey
        )
        .execute(testEnv.client)
        let contractCreateReceipt = try await contractCreateResponse.getReceipt(testEnv.client)
        let contractId = try XCTUnwrap(contractCreateReceipt.contractId)
        await registerContract(contractId, adminKey: testEnv.operator.privateKey)

        // Then
        let record = try await contractCreateResponse.getRecord(testEnv.client)
        let contractA = try XCTUnwrap(record.receipt.contractId)

        let contractFunctionResult = try XCTUnwrap(record.contractFunctionResult)
        XCTAssertEqual(contractFunctionResult.contractNonces.count, 2)

        let contractANonceInfo = try XCTUnwrap(
            contractFunctionResult.contractNonces.first { $0.contractId == contractA })
        let contractBNonceInfo = try XCTUnwrap(
            contractFunctionResult.contractNonces.first { $0.contractId != contractA })

        // A.nonce = 2
        XCTAssertEqual(contractANonceInfo.nonce, 2)
        // B.nonce = 1
        XCTAssertEqual(contractBNonceInfo.nonce, 1)
    }
}
