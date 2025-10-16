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

    internal func test_CreateContractWithHook() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let lambdaId = try await ContractCreateTransaction()
            .bytecodeFileId(bytecode.fileId)
            .gas(300_000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        // When
        let txResponse = try await ContractCreateTransaction()
            .bytecode(ContractHelpers.bytecode)
            .gas(300_000)
            .addHook(hookCreationDetails)
            .execute(testEnv.client)

        // Then
        let txReceipt = try await txResponse.getReceipt(testEnv.client)
        XCTAssertNotNil(txReceipt.contractId)
    }

    internal func test_CreateContractWithHookWithStorageUpdates() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let lambdaId = try await ContractCreateTransaction()
            .bytecodeFileId(bytecode.fileId)
            .gas(300_000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        var slot = LambdaStorageSlot()
        slot.key = Data([0x01, 0x23, 0x45])
        slot.value = Data([0x67, 0x89, 0xAB])

        var update = LambdaStorageUpdate()
        update.storageSlot = slot

        lambdaEvmHook.addStorageUpdate(update)

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        // When
        let txResponse = try await ContractCreateTransaction()
            .bytecode(ContractHelpers.bytecode)
            .gas(300_000)
            .addHook(hookCreationDetails)
            .execute(testEnv.client)

        // Then
        let txReceipt = try await txResponse.getReceipt(testEnv.client)
        XCTAssertNotNil(txReceipt.contractId)
    }

    internal func test_CannotCreateContractWithNoContractIdForHook() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let lambdaEvmHook = LambdaEvmHook()

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        // When / Then
        await assertThrowsHErrorAsync(
            try await ContractCreateTransaction()
                .bytecode(ContractHelpers.bytecode)
                .gas(300_000)
                .addHook(hookCreationDetails)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.receiptStatus(status: _)`")
                return
            }
            XCTAssertEqual(status, .invalidHookCreationSpec)
        }
    }

    internal func test_CannotCreateContractWithDuplicateHookId() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let lambdaId = try await ContractCreateTransaction()
            .bytecodeFileId(bytecode.fileId)
            .gas(300_000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        // When / Then
        await assertThrowsHErrorAsync(
            try await ContractCreateTransaction()
                .bytecode(ContractHelpers.bytecode)
                .gas(300_000)
                .addHook(hookCreationDetails)
                .addHook(hookCreationDetails)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.transactionPreCheckStatus(status: _)`")
                return
            }
            XCTAssertEqual(status, .hookIdRepeatedInCreationDetails)
        }
    }

    internal func test_CreateContractWithHookWithAdminKey() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let adminKey = PrivateKey.generateEcdsa()
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let lambdaId = try await ContractCreateTransaction()
            .bytecodeFileId(bytecode.fileId)
            .gas(300_000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook,
            adminKey: .single(adminKey.publicKey)
        )

        // When
        let txResponse = try await ContractCreateTransaction()
            .bytecode(ContractHelpers.bytecode)
            .gas(300_000)
            .addHook(hookCreationDetails)
            .execute(testEnv.client)

        // Then
        let txReceipt = try await txResponse.getReceipt(testEnv.client)
        XCTAssertNotNil(txReceipt.contractId)
    }
}
