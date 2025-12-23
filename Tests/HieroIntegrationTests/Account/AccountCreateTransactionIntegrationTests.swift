// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class AccountCreateTransactionIntegrationTests: HieroIntegrationTestCase {

    internal func test_InitialBalanceAndKey() async throws {
        // Given
        let key = PrivateKey.generateEd25519()

        // When
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(key.publicKey))
                .initialBalance(TestConstants.testSmallHbarBalance),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfo(info, accountId: accountId, key: .single(key.publicKey))
        XCTAssertEqual(info.balance, 1)
        XCTAssertEqual(info.autoRenewPeriod, .days(90))
        XCTAssertEqual(info.proxyReceived, 0)
    }

    internal func test_NoInitialBalance() async throws {
        // Given
        let key = PrivateKey.generateEd25519()

        // When
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(key.publicKey)),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfo(info, accountId: accountId, key: .single(key.publicKey))
        XCTAssertEqual(info.balance, 0)
        XCTAssertEqual(info.autoRenewPeriod, .days(90))
        XCTAssertEqual(info.proxyReceived, 0)
    }

    internal func test_MissingKeyFails() async throws {
        await assertPrecheckStatus(
            try await AccountCreateTransaction().execute(testEnv.client),
            .keyRequired
        )
    }

    internal func test_AliasKey() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let aliasId = key.toAccountId(shard: 0, realm: 0)

        // When
        _ = try await TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, "-0.01")
            .hbarTransfer(aliasId, "0.01")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await AccountInfoQuery().accountId(aliasId).execute(testEnv.client)
        await registerAccount(info.accountId, key: key)
        XCTAssertEqual(info.aliasKey, key.publicKey)
    }

    internal func test_AliasFromAdminKey() async throws {
        // Given
        let (adminKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(adminKey.publicKey))
                .alias(evmAddress),
            key: adminKey
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfoWithEvmAddress(
            info, accountId: accountId, key: .single(adminKey.publicKey), evmAddress: evmAddress)
    }

    internal func test_AliasFromAdminKeyWithReceiverSigRequired() async throws {
        // Given
        let (adminKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(adminKey.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .sign(adminKey),
            key: adminKey
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfoWithEvmAddress(
            info, accountId: accountId, key: .single(adminKey.publicKey), evmAddress: evmAddress)
    }

    internal func test_AliasFromAdminKeyWithReceiverSigRequiredMissingSignatureFails()
        async throws
    {
        // Given
        let (adminKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When / Then
        await assertReceiptStatus(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(adminKey.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_Alias() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let (aliasKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .keyWithoutAlias(.single(key.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .sign(aliasKey),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfoWithEvmAddress(info, accountId: accountId, key: .single(key.publicKey), evmAddress: evmAddress)
    }

    internal func test_AliasMissingSignatureFails() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let (_, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When / Then
        await assertReceiptStatus(
            try await AccountCreateTransaction()
                .keyWithoutAlias(.single(key.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_AliasWithReceiverSigRequired() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let (aliasKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(key.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .sign(key)
                .sign(aliasKey),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        assertAccountInfoWithEvmAddress(info, accountId: accountId, key: .single(key.publicKey), evmAddress: evmAddress)
    }

    internal func test_AliasWithReceiverSigRequiredMissingSignatureFails() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        let (_, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When / Then
        await assertReceiptStatus(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(key.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_AliasWithoutBothKeySignaturesFails() async throws {
        // Given
        let key = PrivateKey.generateEd25519()
        _ = try await createAccount(
            try AccountCreateTransaction().keyWithoutAlias(.single(key.publicKey)).freezeWith(testEnv.client), key: key)

        // When / Then
        let aliasKey = PrivateKey.generateEcdsa()
        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithAlias(.single(key.publicKey), aliasKey)
                .freezeWith(testEnv.client)
                .sign(aliasKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating account"
        )
    }

    internal func test_VerifyKeyAndAliasAreFromAliasAccount() async throws {
        // Given
        let (ecdsaKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithAlias(ecdsaKey)
                .freezeWith(testEnv.client)
                .sign(ecdsaKey),
            key: ecdsaKey
        )

        // Then
        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertNotNil(info.accountId)
        XCTAssertEqual(info.key, .single(ecdsaKey.publicKey))
        assertAccountInfoContainsEvmAddress(info, evmAddress: evmAddress)
    }

    internal func test_VerifySetKeyWithEcdsaKeyAndAlias() async throws {
        // Given
        let (ecdsaKey, evmAddress) = try generateEcdsaKeyWithEvmAddress()
        let key = PrivateKey.generateEd25519()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithAlias(.single(key.publicKey), ecdsaKey)
                .freezeWith(testEnv.client)
                .sign(key)
                .sign(ecdsaKey),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertNotNil(info.accountId)
        XCTAssertEqual(info.key, .single(key.publicKey))
        assertAccountInfoContainsEvmAddress(info, evmAddress: evmAddress)
    }

    internal func test_VerifySetKeyWithoutAlias() async throws {
        // Given
        let key = PrivateKey.generateEcdsa()

        // When
        let accountId = try await createAccount(
            try AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(key.publicKey))
                .freezeWith(testEnv.client)
                .sign(key),
            key: key
        )

        // Then
        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertNotNil(info.accountId)
        XCTAssertEqual(info.key, .single(key.publicKey))
        XCTAssertTrue(isZeroEvmAddress(try info.contractAccountId.bytes))
    }

    internal func test_SetKeyWithAliasWithEd25519KeyFails() async throws {
        // Given
        let key = PrivateKey.generateEd25519()

        // When / Then
        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithAlias(key)
                .freezeWith(testEnv.client)
                .sign(key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating account"
        )
    }

    internal func test_CreateTransactionWithLambdaHook() async throws {

        // Given
        let ecdsaPrivateKey = PrivateKey.generateEcdsa()

        // Create a real contract first
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
            hookExtensionPoint: .accountAllowanceHook, hookId: 1, lambdaEvmHook: lambdaEvmHook)

        // When / Then
        var txReceipt: Hiero.TransactionReceipt!
        do {
            txReceipt = try await AccountCreateTransaction()
                .keyWithoutAlias(.single(ecdsaPrivateKey.publicKey))
                .addHook(hookCreationDetails)
                .freezeWith(testEnv.client)
                .sign(ecdsaPrivateKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }

        XCTAssertNotNil(txReceipt.accountId)
    }

    func test_CreateTransactionWithLambdaHookAndStorageUpdates() async throws {

        // Given
        let ecdsaPrivateKey = PrivateKey.generateEcdsa()

        // Create a real contract first
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

        print("contractId: \(contractId)")

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = contractId

        var lambdaStorageSlot = LambdaStorageSlot()
        lambdaStorageSlot.key = Data([0x01, 0x23, 0x45])
        lambdaStorageSlot.value = Data([0x67, 0x89, 0xAB])

        var lambdaStorageUpdate = LambdaStorageUpdate()
        lambdaStorageUpdate.storageSlot = lambdaStorageSlot

        lambdaEvmHook.addStorageUpdate(lambdaStorageUpdate)

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook, hookId: 1, lambdaEvmHook: lambdaEvmHook)

        // When / Then
        do {
            let txResponse = try await AccountCreateTransaction()
                .keyWithoutAlias(.single(ecdsaPrivateKey.publicKey))
                .addHook(hookCreationDetails)
                .freezeWith(testEnv.client)
                .sign(ecdsaPrivateKey)
                .execute(testEnv.client)

            let txReceipt = try await txResponse.getReceipt(testEnv.client)
            XCTAssertNotNil(txReceipt.accountId)
        } catch {
            XCTFail("Unexpected throw: \(error)")
        }
    }

    func test_CreateTransactionWithLambdaHookWithNoContractId() async throws {

        // Given
        let ecdsaPrivateKey = PrivateKey.generateEcdsa()

        var lambdaEvmHook = LambdaEvmHook()

        var lambdaStorageSlot = LambdaStorageSlot()
        lambdaStorageSlot.key = Data([0x01, 0x23, 0x45])
        lambdaStorageSlot.value = Data([0x67, 0x89, 0xAB])

        var lambdaStorageUpdate = LambdaStorageUpdate()
        lambdaStorageUpdate.storageSlot = lambdaStorageSlot

        lambdaEvmHook.addStorageUpdate(lambdaStorageUpdate)

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook, hookId: 1, lambdaEvmHook: lambdaEvmHook)

        // When / Then (expecting a precheck failure)
        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
                .keyWithoutAlias(.single(ecdsaPrivateKey.publicKey))
                .addHook(hookCreationDetails)
                .execute(testEnv.client)
                .getReceipt(testEnv.client), "expected error creating account"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.receiptStatus(status: _)`")
                return
            }

            XCTAssertEqual(status, .invalidHookCreationSpec)
        }
    }

    func test_CreateTransactionWithSameLambdaHookIds() async throws {

        // Given
        let ecdsaPrivateKey = PrivateKey.generateEcdsa()

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = testContractId

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook, hookId: 1, lambdaEvmHook: lambdaEvmHook)

        // When / Then — expect precheck error when duplicate hook IDs supplied
        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
                .keyWithoutAlias(.single(ecdsaPrivateKey.publicKey))
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
}
