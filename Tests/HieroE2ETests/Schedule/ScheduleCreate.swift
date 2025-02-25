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

internal class ScheduleCreate: XCTestCase {
    // Seconds in a day
    private let testSeconds: UInt64 = 86400

    internal func testTransfer() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()
        let key3 = PrivateKey.generateEd25519()

        let keyList: KeyList = [.single(key1.publicKey), .single(key2.publicKey), .single(key3.publicKey)]

        // Create the account with the `KeyList`
        let transaction = AccountCreateTransaction()
        let accountReceipt =
            try await transaction
            .keyWithoutAlias(.keyList(keyList))
            .initialBalance(Hbar(1))
            .execute(testEnv.client)

            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(accountReceipt.accountId)

        // Create a transfer transaction with 2/3 signatures.
        let transfer = TransferTransaction().hbarTransfer(accountId, Hbar(-1)).hbarTransfer(
            testEnv.operator.accountId, Hbar(1))

        // Schedule the transactoin
        let scheduled = transfer.schedule()

        let receipt = try await scheduled.execute(testEnv.client).getReceipt(testEnv.client)

        // Get the schedule ID from the receipt
        let scheduleId = try XCTUnwrap(receipt.scheduleId)

        do {
            // Get the schedule info to see if `signatories` is populated with 2/3 signatures
            let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)
            XCTAssertNil(info.executedAt)
        }

        // Finally send this last signature to Hiero. This last signature _should_ mean the transaction executes
        // since all 3 signatures have been provided.
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .sign(key1)
            .sign(key2)
            .sign(key3)
            .execute(testEnv.client)

            .getReceipt(testEnv.client)

        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        _ = try XCTUnwrap(info.executedAt)

        _ = try await AccountDeleteTransaction()
            .accountId(accountId)
            .transferAccountId(testEnv.operator.accountId)
            .sign(key1)
            .sign(key2)
            .sign(key3)
            .execute(testEnv.client)

            .getReceipt(testEnv.client)
    }

    internal func testDoubleScheduleFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv, balance: 1)

        let receipt1 = try await TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .hbarTransfer(account.id, Hbar(1))
            .schedule()
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let scheduleId1 = try XCTUnwrap(receipt1.scheduleId)

        let info1 = try await ScheduleInfoQuery(scheduleId: scheduleId1).execute(testEnv.client)

        _ = try XCTUnwrap(info1.executedAt)

        let transfer = TransferTransaction()

        transfer.hbarTransfer(testEnv.operator.accountId, Hbar(-1)).hbarTransfer(account.id, Hbar(1))

        await assertThrowsHErrorAsync(
            try await transfer.schedule().execute(testEnv.client).getReceipt(testEnv.client),
            "expected topic delete to fail"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .identicalScheduleAlreadyCreated)
        }

    }

    internal func testTopicMessage() async throws {
        let testEnv = try TestEnvironment.nonFree

        // This is the submit key
        let key = PrivateKey.generateEd25519()

        let topicReceipt = try await TopicCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .autoRenewAccountId(testEnv.operator.accountId)
            .topicMemo("HCS Topic_")
            .submitKey(.single(key.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(topicReceipt.topicId)

        let transaction = TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message("scheduled hcs message".data(using: .utf8)!)

        // create schedule
        let receipt =
            try await transaction
            .schedule()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .payerAccountId(testEnv.operator.accountId)
            .scheduleMemo(
                "mirror scheduled E2E signature on create and sign_\(Date())"
            )
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let scheduleId = try XCTUnwrap(receipt.scheduleId)

        do {
            let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

            XCTAssertEqual(info.scheduleId, scheduleId)
        }

        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        _ = try XCTUnwrap(info.executedAt)
    }

    internal func testCanSignSchedule() async throws {
        let testEnv = try TestEnvironment.nonFree

        let privateKey = PrivateKey.generateEd25519()

        let accountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .initialBalance(Hbar(10))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        // Create transaction to schedule
        let transfer = TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(accountId, -Hbar(1))

        // Schedule transaction
        let scheduleId = try await transfer.schedule().expirationTime(.now + .seconds(testSeconds))
            .scheduleMemo("HIP-423 e2e Test")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .scheduleId!

        var info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the schedule is not yet executed
        XCTAssertNil(info.executedAt)

        // Schedule sign
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(testEnv.client)
            .sign(privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the schedule is executed
        XCTAssertNotNil(info.executedAt)

        XCTAssertNil(scheduleId.checksum)
        XCTAssertEqual(scheduleId, try ScheduleId.fromBytes(scheduleId.toBytes()))
        XCTAssertNotEqual(scheduleId.hashValue, 0)
    }

    internal func testScheduleAheadOneYearFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let privateKey = PrivateKey.generateEd25519()

        let accountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .initialBalance(Hbar(10))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        // Create transaction to schedule
        let transfer = TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(accountId, -Hbar(1))

        await assertThrowsHErrorAsync(
            // Schedule transaction should fail
            try await transfer.schedule().expirationTime(.now + .days(365))
                .scheduleMemo("HIP-423 e2e Test")
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected topic delete to fail"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .scheduleExpirationTimeTooFarInFuture)
        }
    }

    internal func testScheduleInThePastFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let privateKey = PrivateKey.generateEd25519()

        let accountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .initialBalance(Hbar(10))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        // Create transaction to schedule
        let transfer = TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(accountId, -Hbar(1))

        await assertThrowsHErrorAsync(
            // Schedule transaction should fail
            try await transfer.schedule().expirationTime(.now - .seconds(10))
                .scheduleMemo("HIP-423 e2e Test")
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected topic delete to fail"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .scheduleExpirationTimeMustBeHigherThanConsensusTime)
        }
    }

    internal func testSignScheduleAndWaitForExpiry() async throws {
        let testEnv = try TestEnvironment.nonFree

        let privateKey = PrivateKey.generateEd25519()

        let accountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .initialBalance(Hbar(10))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        // Create transaction to schedule
        let transfer = TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(accountId, -Hbar(1))

        // Schedule transaction
        let scheduleId = try await transfer.schedule().expirationTime(.now + .seconds(testSeconds))
            .isWaitForExpiry(true)
            .scheduleMemo("HIP-423 e2e Test")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .scheduleId!

        var info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the schedule is not yet executed
        XCTAssertNil(info.executedAt)

        // Schedule sign
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(testEnv.client)
            .sign(privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the schedule is executed
        XCTAssertNil(info.executedAt)

        XCTAssertNil(scheduleId.checksum)
        XCTAssertEqual(scheduleId, try ScheduleId.fromBytes(scheduleId.toBytes()))
        XCTAssertNotEqual(scheduleId.hashValue, 0)
    }

    internal func testSignWithMultiSigAndUpdateSigningRequirements() async throws {
        let testEnv = try TestEnvironment.nonFree

        let privateKey1 = PrivateKey.generateEd25519()
        let privateKey2 = PrivateKey.generateEd25519()
        let privateKey3 = PrivateKey.generateEd25519()
        let privateKey4 = PrivateKey.generateEd25519()

        let keyList = KeyList.init(
            keys: [.single(privateKey1.publicKey), .single(privateKey2.publicKey), .single(privateKey3.publicKey)],
            threshold: 2)

        let accountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.keyList(keyList))
            .initialBalance(Hbar(10))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        // Create transaction to schedule
        let transfer = TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(accountId, -Hbar(1))

        // Schedule transaction
        let scheduleId = try await transfer.schedule().expirationTime(.now + .seconds(testSeconds))
            .scheduleMemo("HIP-423 e2e Test")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .scheduleId!

        var info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the schedule is not yet executed
        XCTAssertNil(info.executedAt)

        // Schedule sign
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(testEnv.client)
            .sign(privateKey1)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the schedule is still not executed
        XCTAssertNil(info.executedAt)

        // Update the signing requirements
        _ = try await AccountUpdateTransaction()
            .accountId(accountId)
            .key(.single(privateKey4.publicKey))
            .freezeWith(testEnv.client)
            .sign(privateKey1)
            .sign(privateKey2)
            .sign(privateKey4)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the schedule is still not executed
        XCTAssertNil(info.executedAt)

        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(testEnv.client)
            .sign(privateKey4)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the schedule is executed
        XCTAssertNotNil(info.executedAt)
    }

    internal func testSignWithMultiSig() async throws {
        let testEnv = try TestEnvironment.nonFree

        let privateKey1 = PrivateKey.generateEd25519()
        let privateKey2 = PrivateKey.generateEd25519()
        let privateKey3 = PrivateKey.generateEd25519()

        let keyList = KeyList.init(
            keys: [.single(privateKey1.publicKey), .single(privateKey2.publicKey), .single(privateKey3.publicKey)],
            threshold: 2)

        let accountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.keyList(keyList))
            .initialBalance(Hbar(10))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId!

        // Create transaction to schedule
        let transfer = TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(accountId, -Hbar(1))

        // Schedule transaction
        let scheduleId = try await transfer.schedule().expirationTime(.now + .seconds(testSeconds))
            .scheduleMemo("HIP-423 e2e Test")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .scheduleId!

        var info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the transaction has still not executed
        XCTAssertNil(info.executedAt)

        // Schedule sign with one key
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(testEnv.client)
            .sign(privateKey1)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the transaction has still not executed
        XCTAssertNil(info.executedAt)

        // Update the signing requirements
        _ = try await AccountUpdateTransaction()
            .accountId(accountId)
            .key(.single(privateKey1.publicKey))
            .freezeWith(testEnv.client)
            .sign(privateKey1)
            .sign(privateKey2)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the transaction has still not executed
        XCTAssertNil(info.executedAt)

        // Schedule sign with one key
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(testEnv.client)
            .sign(privateKey2)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        // Verify the transaction has executed
        XCTAssertNotNil(info.executedAt)
    }

}
