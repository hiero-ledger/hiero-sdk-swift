// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ContractCreateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given / When
        let contractId = try await createStandardContract()

        // Then
        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)
        assertStandardContractInfo(
            info,
            contractId: contractId,
            adminKey: .single(testEnv.operator.privateKey.publicKey)
        )
    }

    internal func test_NoAdminKey() async throws {
        // Given / When
        let contractId = try await createImmutableContract()

        // Then
        let info = try await ContractInfoQuery(contractId: contractId).execute(testEnv.client)
        assertImmutableContractInfo(info, contractId: contractId)
    }

    internal func test_UnsetGasFails() async throws {
        // Given
        let fileId = try await createContractBytecodeFile()

        // When / Then
        await assertPrecheckStatus(
            try await ContractCreateTransaction()
                .constructorParameters(TestConstants.standardContractConstructorParameters())
                .bytecodeFileId(fileId)
                .execute(testEnv.client),
            .insufficientGas
        )
    }

    internal func test_ConstructorParametersUnsetFails() async throws {
        // Given
        let fileId = try await createContractBytecodeFile()

        // When / Then
        await assertReceiptStatus(
            try await ContractCreateTransaction()
                .gas(TestConstants.standardContractGas)
                .bytecodeFileId(fileId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .contractRevertExecuted
        )
    }

    internal func test_BytecodeFileIdUnsetFails() async throws {
        // Given / When / Then
        await assertReceiptStatus(
            try await ContractCreateTransaction()
                .gas(TestConstants.standardContractGas)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidFileID
        )
    }

    internal func test_CreateContractWithHook() async throws {

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
