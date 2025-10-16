// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class ContractUpdate: XCTestCase {

    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let contractId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: true)

        addTeardownBlock {
            _ = try await ContractDeleteTransaction(contractId: contractId)
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        _ = try await ContractUpdateTransaction(contractId: contractId, contractMemo: "[swift::e2e::ContractUpdate]")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)

        XCTAssertEqual(info.contractId, contractId)
        XCTAssertEqual(String(describing: info.accountId), String(describing: info.contractId))
        XCTAssertEqual(info.adminKey, .single(testEnv.operator.privateKey.publicKey))
        XCTAssertEqual(info.storage, 128)
        XCTAssertEqual(info.contractMemo, "[swift::e2e::ContractUpdate]")
    }

    internal func testMissingContractIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await ContractUpdateTransaction(contractMemo: "[swift::e2e::ContractUpdate]")
                .execute(testEnv.client),
            "expected error updating contract"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidContractID)
        }
    }

    internal func testImmutableContractFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let contractId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: false)

        await assertThrowsHErrorAsync(
            try await ContractUpdateTransaction(contractId: contractId, contractMemo: "[swift::e2e::ContractUpdate]")
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error updating contract"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .modifyingImmutableContract)
        }
    }

    internal func test_CanAddHookToContract() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let lambdaId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: false)
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let contractId = try await ContractCreateTransaction()
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
        do {
            _ = try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToCreate(hookCreationDetails)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CannotAddDuplicateHooksToContract() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let lambdaId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: false)
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let contractId = try await ContractCreateTransaction()
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
            try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToCreate(hookCreationDetails)
                .addHookToCreate(hookCreationDetails)
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

    internal func test_CannotAddHookToContractThatAlreadyExists() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let lambdaId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: true)
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let contractId = try await ContractCreateTransaction()
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

        _ = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToCreate(hookCreationDetails)
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertThrowsHErrorAsync(
            try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToCreate(hookCreationDetails)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.transactionPreCheckStatus(status: _)`")
                return
            }
            XCTAssertEqual(status, .hookIdInUse)
        }
    }

    internal func test_CanAddHookToContractWithStorageUpdates() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let lambdaId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: false)
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let contractId = try await ContractCreateTransaction()
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

        // When / Then
        do {
            _ = try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToCreate(hookCreationDetails)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CanDeleteHookFromContract() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let lambdaId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: true)
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let contractId = try await ContractCreateTransaction()
            .bytecodeFileId(bytecode.fileId)
            .gas(300_000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        let hookId: Int64 = 1
        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: hookId,
            lambdaEvmHook: lambdaEvmHook
        )

        _ = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToCreate(hookCreationDetails)
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        do {
            _ = try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToDelete(hookId)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    internal func test_CannotDeleteNonExistentHookFromContract() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let contractId = try await ContractCreateTransaction()
            .bytecodeFileId(bytecode.fileId)
            .gas(300_000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        // When / Then
        await assertThrowsHErrorAsync(
            try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToDelete(999)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.transactionPreCheckStatus(status: _)`")
                return
            }
            XCTAssertEqual(status, .hookNotFound)
        }
    }

    internal func test_CannotAddAndDeleteSameHookFromContract() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let lambdaId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: true)
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let contractId = try await ContractCreateTransaction()
            .bytecodeFileId(bytecode.fileId)
            .gas(300_000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        let hookId: Int64 = 1
        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: hookId,
            lambdaEvmHook: lambdaEvmHook
        )

        // When / Then
        await assertThrowsHErrorAsync(
            try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToCreate(hookCreationDetails)
                .addHookToDelete(hookId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.transactionPreCheckStatus(status: _)`")
                return
            }
            XCTAssertEqual(status, .hookNotFound)
        }
    }

    internal func test_CannotDeleteAlreadyDeletedHookFromContract() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let lambdaId = try await ContractHelpers.makeContract(testEnv, operatorAdminKey: true)
        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let contractId = try await ContractCreateTransaction()
            .bytecodeFileId(bytecode.fileId)
            .gas(300_000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        let hookId: Int64 = 1
        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: hookId,
            lambdaEvmHook: lambdaEvmHook
        )

        _ = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToCreate(hookCreationDetails)
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToDelete(hookId)
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertThrowsHErrorAsync(
            try await ContractUpdateTransaction()
                .contractId(contractId)
                .addHookToDelete(hookId)
                .freezeWith(testEnv.client)
                .sign(testEnv.operator.privateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.transactionPreCheckStatus(status: _)`")
                return
            }
            XCTAssertEqual(status, .hookNotFound)
        }
    }
}
