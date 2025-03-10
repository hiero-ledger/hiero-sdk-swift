// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class ContractCreate: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let receipt = try await ContractCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .gas(200000)
            .constructorParameters(ContractFunctionParameters().addString("Hello from Hiero."))
            .bytecodeFileId(bytecode.fileId)
            .contractMemo("[e2e::ContractCreateTransaction]")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let contractId = try XCTUnwrap(receipt.contractId)

        addTeardownBlock {
            _ = try await ContractDeleteTransaction(contractId: contractId)
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)

        XCTAssertEqual(info.contractId, contractId)
        XCTAssertEqual(String(describing: info.accountId), String(describing: info.contractId))
        XCTAssertEqual(info.adminKey, .single(testEnv.operator.privateKey.publicKey))
        XCTAssertEqual(info.storage, 128)
        XCTAssertEqual(info.contractMemo, "[e2e::ContractCreateTransaction]")
    }

    internal func testNoAdminKey() async throws {
        let testEnv = try TestEnvironment.nonFree

        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let receipt = try await ContractCreateTransaction()
            .gas(200000)
            .constructorParameters(ContractFunctionParameters().addString("Hello from Hiero."))
            .bytecodeFileId(bytecode.fileId)
            .contractMemo("[e2e::ContractCreateTransaction]")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let contractId = try XCTUnwrap(receipt.contractId)

        // note that there is no teardown,
        // that's because the lack of admin key does mean that there's well,
        // no way to delete the contract.

        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)

        XCTAssertEqual(info.contractId, contractId)
        XCTAssertEqual(String(describing: info.accountId), String(describing: info.contractId))
        XCTAssertNotNil(info.adminKey)
        XCTAssertEqual(info.storage, 128)
        XCTAssertEqual(info.contractMemo, "[e2e::ContractCreateTransaction]")
    }

    internal func testUnsetGasFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        await assertThrowsHErrorAsync(
            try await ContractCreateTransaction()
                .constructorParameters(ContractFunctionParameters().addString("Hello from Hiero."))
                .bytecodeFileId(bytecode.fileId)
                .contractMemo("[e2e::ContractCreateTransaction]")
                .execute(testEnv.client),
            "expected error creating contract"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .insufficientGas)
        }
    }

    internal func testConstructorParametersUnsetFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        await assertThrowsHErrorAsync(
            try await ContractCreateTransaction()
                .gas(100000)
                .bytecodeFileId(bytecode.fileId)
                .contractMemo("[e2e::ContractCreateTransaction]")
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating contract"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .contractRevertExecuted)
        }
    }

    internal func bytecodeFileIdUnsetFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await ContractCreateTransaction()
                .gas(100000)
                .constructorParameters(ContractFunctionParameters().addString("Hello from Hiero."))
                .contractMemo("[e2e::ContractCreateTransaction]")
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating contract"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidFileID)
        }
    }
}
