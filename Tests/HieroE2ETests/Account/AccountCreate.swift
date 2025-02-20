/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import Hiero
import XCTest

internal final class AccountCreate: XCTestCase {
    internal func testInitialBalanceAndKey() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key = PrivateKey.generateEd25519()

        try await testEnv.ratelimits.accountCreate()

        let receipt = try await AccountCreateTransaction()
            .key(.single(key.publicKey))
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
            .key(.single(key.publicKey))
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

    // there's a disagreement between Java and Swift here.
    // internal func testManagesExpiration() async throws {
    //     let testEnv = try TestEnvironment.nonFree

    //     let key = PrivateKey.generateEd25519()

    //     let receipt = try await AccountCreateTransaction()
    //         .key(.single(key.publicKey))
    //         .transactionId(
    //             .withValidStart(
    //                 testEnv.operator.accountId,
    //                 .now - .seconds(40)
    //             )
    //         )
    //         .transactionValidDuration(.seconds(30))
    //         .freezeWith(testEnv.client)
    //         .execute(testEnv.client)
    //         .getReceipt(testEnv.client)

    //     let accountId = try XCTUnwrap(receipt.accountId)

    //        addTeardownBlock { try await Account(id: accountId, key: key).delete(testEnv) }

    //     let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

    //     XCTAssertEqual(info.accountId, accountId)
    //     XCTAssertFalse(info.isDeleted)
    //     XCTAssertEqual(info.key, .single(key.publicKey))
    //     XCTAssertEqual(info.balance, 0)
    //     XCTAssertEqual(info.autoRenewPeriod, .days(90))
    //     // fixme: ensure no warning gets emitted.
    //     // XCTAssertNil(info.proxyAccountId)
    //     XCTAssertEqual(info.proxyReceived, 0)
    // }

    internal func testAliasFromAdminKey() async throws {
        // Tests the third row of this table
        // https://github.com/hashgraph/hedera-improvement-proposal/blob/d39f740021d7da592524cffeaf1d749803798e9a/HIP/hip-583.md#signatures
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEcdsa()
        let evmAddress = try XCTUnwrap(adminKey.publicKey.toEvmAddress())

        try await testEnv.ratelimits.accountCreate()
        let receipt = try await AccountCreateTransaction()
            .key(.single(adminKey.publicKey))
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
            .key(.single(adminKey.publicKey))
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
                .key(.single(adminKey.publicKey))
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
            .key(.single(adminKey.publicKey))
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
                .key(.single(adminKey.publicKey))
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
            .key(.single(adminKey.publicKey))
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
                .key(.single(adminKey.publicKey))
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
}
