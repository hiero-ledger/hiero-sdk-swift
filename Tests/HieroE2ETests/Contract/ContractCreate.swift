// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class ContractCreate: XCTestCase {

    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let bytecode = try await File.forContent(ContractHelpers.bytecode, testEnv)

        let receipt = try await ContractCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .gas(300000)
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
            .gas(300000)
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
        let lambdaId = try await ContractCreateTransaction()
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
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
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
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
        let lambdaId = try await ContractCreateTransaction()
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
            .gas(300000)
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
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
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
                .bytecode(
                    Data(
                        hexEncoded:
                            "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                    )!
                )
                .gas(300000)
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
        let contractResponse = try await ContractCreateTransaction()
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
            .gas(300000)
            .execute(testEnv.client)
        let contractReceipt = try await contractResponse.getReceipt(testEnv.client)
        let contractId = try XCTUnwrap(contractReceipt.contractId)

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = contractId

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        // When / Then
        await assertThrowsHErrorAsync(
            try await ContractCreateTransaction()
                .bytecode(
                    Data(
                        hexEncoded:
                            "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                    )!
                )
                .gas(300000)
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

        let lambdaId = try await ContractCreateTransaction()
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
            .gas(300000)
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
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
            .gas(300000)
            .addHook(hookCreationDetails)
            .execute(testEnv.client)

        // Then
        let txReceipt = try await txResponse.getReceipt(testEnv.client)
        XCTAssertNotNil(txReceipt.contractId)
    }
}
