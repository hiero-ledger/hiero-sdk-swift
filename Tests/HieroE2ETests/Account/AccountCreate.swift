// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class AccountCreate: XCTestCase {

    private let testContractId = ContractId(shard: 1, realm: 2, num: 3)

    internal func testInitialBalanceAndKey() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key = PrivateKey.generateEd25519()

        try await testEnv.ratelimits.accountCreate()

        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(Hbar(1))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock { try await Account(id: accountId, key: key).delete(testEnv) }

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.key, .single(key.publicKey))
        XCTAssertEqual(info.balance, 1)
        XCTAssertEqual(info.autoRenewPeriod, .days(90))
        // fixme: ensure no warning gets emitted.
        // XCTAssertNil(info.proxyAccountId)
        XCTAssertEqual(info.proxyReceived, 0)
    }

    internal func testNoInitialBalance() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key = PrivateKey.generateEd25519()

        try await testEnv.ratelimits.accountCreate()

        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock { try await Account(id: accountId, key: key).delete(testEnv) }

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.key, .single(key.publicKey))
        XCTAssertEqual(info.balance, 0)
        XCTAssertEqual(info.autoRenewPeriod, .days(90))
        // fixme: ensure no warning gets emitted.
        // XCTAssertNil(info.proxyAccountId)
        XCTAssertEqual(info.proxyReceived, 0)
    }

    internal func testMissingKeyFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        try await testEnv.ratelimits.accountCreate()
        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction().execute(testEnv.client),
            "expected error creating account"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.transactionPreCheckStatus(status: _)`")
                return
            }

            XCTAssertEqual(status, .keyRequired)
        }
    }

    internal func testAliasKey() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key = PrivateKey.generateEd25519()

        let aliasId = key.toAccountId(shard: 0, realm: 0)

        _ = try await TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, "-0.01")
            .hbarTransfer(aliasId, "0.01")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let info = try await AccountInfoQuery().accountId(aliasId).execute(testEnv.client)

        addTeardownBlock { try await Account(id: info.accountId, key: key).delete(testEnv) }

        XCTAssertEqual(info.aliasKey, key.publicKey)
    }

    internal func testAliasFromAdminKey() async throws {
        // Tests the third row of this table
        // https://github.com/hashgraph/hedera-improvement-proposal/blob/d39f740021d7da592524cffeaf1d749803798e9a/HIP/hip-583.md#signatures
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEcdsa()
        let evmAddress = try XCTUnwrap(adminKey.publicKey.toEvmAddress())

        try await testEnv.ratelimits.accountCreate()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(adminKey.publicKey))
            .alias(evmAddress)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock { try await Account(id: accountId, key: adminKey).delete(testEnv) }

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
        XCTAssertEqual("0x\(info.contractAccountId)", evmAddress.toString())
        XCTAssertEqual(info.key, .single(adminKey.publicKey))
    }

    internal func testAliasFromAdminKeyWithReceiverSigRequired() async throws {
        // Tests the fourth row of this table
        // https://github.com/hashgraph/hedera-improvement-proposal/blob/d39f740021d7da592524cffeaf1d749803798e9a/HIP/hip-583.md#signatures
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEcdsa()
        let evmAddress = try XCTUnwrap(adminKey.publicKey.toEvmAddress())

        try await testEnv.ratelimits.accountCreate()
        let receipt = try await AccountCreateTransaction()
            .receiverSignatureRequired(true)
            .keyWithoutAlias(.single(adminKey.publicKey))
            .alias(evmAddress)
            .freezeWith(testEnv.client)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock { try await Account(id: accountId, key: adminKey).delete(testEnv) }

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
        XCTAssertEqual("0x\(info.contractAccountId)", evmAddress.toString())
        XCTAssertEqual(info.key, .single(adminKey.publicKey))
    }

    internal func testAliasFromAdminKeyWithReceiverSigRequiredMissingSignatureFails()
        async throws
    {
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEcdsa()
        let evmAddress = try XCTUnwrap(adminKey.publicKey.toEvmAddress())

        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(adminKey.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating account"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testAlias() async throws {
        // Tests the fifth row of this table
        // https://github.com/hashgraph/hedera-improvement-proposal/blob/d39f740021d7da592524cffeaf1d749803798e9a/HIP/hip-583.md#signatures
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEd25519()

        let key = PrivateKey.generateEcdsa()
        let evmAddress = try XCTUnwrap(key.publicKey.toEvmAddress())

        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(adminKey.publicKey))
            .alias(evmAddress)
            .freezeWith(testEnv.client)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock { try await Account(id: accountId, key: adminKey).delete(testEnv) }

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
        XCTAssertEqual("0x\(info.contractAccountId)", evmAddress.toString())
        XCTAssertEqual(info.key, .single(adminKey.publicKey))
    }

    internal func testAliasMissingSignatureFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEd25519()

        let key = PrivateKey.generateEcdsa()
        let evmAddress = try XCTUnwrap(key.publicKey.toEvmAddress())

        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
                .keyWithoutAlias(.single(adminKey.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating account"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testAliasWithReceiverSigRequired() async throws {
        // Tests the sixth row of this table
        // https://github.com/hashgraph/hedera-improvement-proposal/blob/d39f740021d7da592524cffeaf1d749803798e9a/HIP/hip-583.md#signatures
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEd25519()

        let key = PrivateKey.generateEcdsa()
        let evmAddress = try XCTUnwrap(key.publicKey.toEvmAddress())

        try await testEnv.ratelimits.accountCreate()
        let receipt = try await AccountCreateTransaction()
            .receiverSignatureRequired(true)
            .keyWithoutAlias(.single(adminKey.publicKey))
            .alias(evmAddress)
            .freezeWith(testEnv.client)
            .sign(key)
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock { try await Account(id: accountId, key: adminKey).delete(testEnv) }

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
        XCTAssertEqual("0x\(info.contractAccountId)", evmAddress.toString())
        XCTAssertEqual(info.key, .single(adminKey.publicKey))
    }

    internal func testAliasWithReceiverSigRequiredMissingSignatureFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEd25519()

        let key = PrivateKey.generateEcdsa()
        let evmAddress = try XCTUnwrap(key.publicKey.toEvmAddress())

        try await testEnv.ratelimits.accountCreate()
        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithoutAlias(.single(adminKey.publicKey))
                .alias(evmAddress)
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating account"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testAliasWithoutBothKeySignaturesFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEd25519()

        _ = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(adminKey.publicKey))
            .freezeWith(testEnv.client)
            .execute(testEnv.client)

        let key = PrivateKey.generateEcdsa()
        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
                .receiverSignatureRequired(true)
                .keyWithAlias(.single(key.publicKey), adminKey)
                .freezeWith(testEnv.client)
                .sign(adminKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating account"
        )
    }

    // Can create account with ECDSA key using setKeyWithAlias, account
    // should have same ECDSA as key and same key's alias
    internal func testVerifyKeyAndAliasAreFromAliasAccount() async throws {
        let testEnv = try TestEnvironment.nonFree
        let ecdsaKey = PrivateKey.generateEcdsa()
        let evmAddress = try XCTUnwrap(ecdsaKey.publicKey.toEvmAddress())

        let accountId = try await AccountCreateTransaction()
            .receiverSignatureRequired(true)
            .keyWithAlias(ecdsaKey)
            .freezeWith(testEnv.client)
            .sign(ecdsaKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertNotNil(info.accountId)
        XCTAssertEqual(info.key, .single(ecdsaKey.publicKey))
        XCTAssertTrue(evmAddress.toString().contains(info.contractAccountId))

        addTeardownBlock { try await Account(id: accountId, key: ecdsaKey).delete(testEnv) }
    }

    internal func testVerifySetKeyWithEcdsaKeyAndAlias() async throws {
        let testEnv = try TestEnvironment.nonFree
        let ecdsaKey = PrivateKey.generateEcdsa()

        let key = PrivateKey.generateEd25519()
        let evmAddress = try XCTUnwrap(ecdsaKey.publicKey.toEvmAddress())

        let accountId = try await AccountCreateTransaction()
            .receiverSignatureRequired(true)
            .keyWithAlias(.single(key.publicKey), ecdsaKey)
            .freezeWith(testEnv.client)
            .sign(key)
            .sign(ecdsaKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        XCTAssertNotNil(info.accountId)
        XCTAssertEqual(info.key, .single(key.publicKey))
        XCTAssertTrue(evmAddress.toString().contains(info.contractAccountId))
    }

    // Can create account with ECDSA key using keyWithoutAlias, account
    // should have same ECDSA as key and no alias
    internal func testVerifySetKeyWithoutAlias() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key = PrivateKey.generateEcdsa()

        let accountId = try await AccountCreateTransaction()
            .receiverSignatureRequired(true)
            .keyWithoutAlias(.single(key.publicKey))
            .freezeWith(testEnv.client)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        let info = try await AccountInfoQuery()
            .accountId(accountId)
            .execute(testEnv.client)

        let isZeroAddress = isZeroAddress(try info.contractAccountId.bytes)

        XCTAssertNotNil(info.accountId)
        XCTAssertEqual(info.key, .single(key.publicKey))
        XCTAssertTrue(isZeroAddress)
        addTeardownBlock { try await Account(id: accountId, key: key).delete(testEnv) }
    }

    // Can't set key with alias with Ed25519 key
    // This is because Ed25519 keys are not supported for alias
    internal func testSetKeyWithAliasWithEd25519KeyFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key = PrivateKey.generateEd25519()

        let accountId = try await AccountCreateTransaction()
            .receiverSignatureRequired(true)
            .keyWithoutAlias(.single(key.publicKey))
            .freezeWith(testEnv.client)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        addTeardownBlock { try await Account(id: accountId, key: key).delete(testEnv) }

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

    // Checks if an address is a zero address (all first 12 bytes are zero)
    internal func isZeroAddress(_ address: [UInt8]) -> Bool {
        // Check first 12 bytes are all zero
        for byte in address[..<12] where byte != 0 {
            return false
        }
        return true
    }

    internal func test_CreateTransactionWithLambdaHook() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let ecdsaPrivateKey = PrivateKey.generateEcdsa()

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = testContractId

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
        let testEnv = try TestEnvironment.nonFree

        // Given
        let ecdsaPrivateKey = PrivateKey.generateEcdsa()

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = testContractId

        var lambdaStorageSlot = LambdaStorageSlot()
        lambdaStorageSlot.key = Data([0x01, 0x23, 0x45])
        lambdaStorageSlot.value = Data([0x67, 0x89, 0xAB])

        var lambdaStorageUpdate = LambdaStorageUpdate()
        lambdaStorageUpdate.storageSlot = lambdaStorageSlot

        lambdaEvmHook.addStorageUpdate(lambdaStorageUpdate)

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

    func test_CreateTransactionWithLambdaHookWithNoContractId() async throws {
        let testEnv = try TestEnvironment.nonFree

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
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("\(error.kind) is not `.transactionPreCheckStatus(status: _)`")
                return
            }

            XCTAssertEqual(status, .invalidHookId)
        }
    }

    func test_CreateTransactionWithSameLambdaHookIds() async throws {
        let testEnv = try TestEnvironment.nonFree

        // Given
        let ecdsaPrivateKey = PrivateKey.generateEcdsa()

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = testContractId

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook, hookId: 1, lambdaEvmHook: lambdaEvmHook)

        // When / Then — expect precheck error when duplicate hook IDs supplied
        await assertThrowsHErrorAsync(
            try await AccountCreateTransaction()
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
