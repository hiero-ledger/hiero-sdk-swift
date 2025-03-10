// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class ContractExecute: XCTestCase {

    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let contractId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: true)

        addTeardownBlock {
            _ = try await ContractDeleteTransaction(contractId: contractId)
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        _ = try await ContractExecuteTransaction(contractId: contractId, gas: 200000)
            .function("setMessage", ContractFunctionParameters().addString("new message"))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testMissingContractIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await ContractExecuteTransaction(gas: 200000)
                .function("setMessage", ContractFunctionParameters().addString("new message"))
                .execute(testEnv.client),
            "expected error executing contract"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidContractID)
        }
    }

    internal func testMissingFunctionParametersFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let contractId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: true)

        addTeardownBlock {
            _ = try await ContractDeleteTransaction(contractId: contractId)
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        await assertThrowsHErrorAsync(
            try await ContractExecuteTransaction(contractId: contractId, gas: 200000)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error executing contract"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .contractRevertExecuted)
        }
    }

    internal func testMissingGasFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let contractId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: true)

        addTeardownBlock {
            _ = try await ContractDeleteTransaction(contractId: contractId)
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        await assertThrowsHErrorAsync(
            try await ContractExecuteTransaction(contractId: contractId)
                .function("setMessage", ContractFunctionParameters().addString("new message"))
                .execute(testEnv.client),
            "expected error executing contract"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .insufficientGas)
        }
    }
}
