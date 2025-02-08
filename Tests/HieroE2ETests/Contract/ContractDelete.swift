// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class ContractDelete: XCTestCase {
    internal func testAdminKey() async throws {
        let testEnv = try TestEnvironment.nonFree

        let contractId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: true)

        _ = try await ContractDeleteTransaction(contractId: contractId)
            .transferAccountId(testEnv.operator.accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let res = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)

        XCTAssertTrue(res.isDeleted)
    }

    internal func testMissingAdminKeyFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let contractId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: false)

        await assertThrowsHErrorAsync(
            try await ContractDeleteTransaction(contractId: contractId)
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error deleting contract"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .modifyingImmutableContract)
        }
    }

    internal func testMissingContractIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await ContractDeleteTransaction()
                .execute(testEnv.client),
            "expected error deleting contract"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidContractID)
        }
    }
}
