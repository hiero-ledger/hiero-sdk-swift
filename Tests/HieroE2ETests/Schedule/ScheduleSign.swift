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
 * See the License for the specific language governing permiss  ions and
 * limitations under the License.
 * ‍
 */

import Hiero
import XCTest

internal final class ScheduleSign: XCTestCase {

    internal func testTransferSign() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()

        let keyList: KeyList = [.single(key1.publicKey), .single(key2.publicKey)]

        // Create a new account with keylist
        let accountReceipt = try await AccountCreateTransaction()
            .key(.keyList(keyList))
            .initialBalance(Hbar(1))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(accountReceipt.accountId)

        addTeardownBlock {
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(key1)
                .sign(key2)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        // Transfer, and sign with key1 upon creating schedule transaction
        let receipt = try await TransferTransaction()
            .hbarTransfer(accountId, Hbar(-1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .schedule()
            .sign(key1)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let scheduleId = try XCTUnwrap(receipt.scheduleId)

        // Sign schedules transaction
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .sign(key2)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        _ = try XCTUnwrap(info.executedAt)

        // Check if signatures in schedule info
        XCTAssertEqual(info.signatories.count, 3)

    }

    internal func testTransferSignWithMissingSigFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()

        let keyList: KeyList = [.single(key1.publicKey), .single(key2.publicKey)]

        // Create new account with key list
        let accountReceipt = try await AccountCreateTransaction()
            .key(.keyList(keyList))
            .initialBalance(Hbar(1))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(accountReceipt.accountId)

        addTeardownBlock {
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(key1)
                .sign(key2)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        // Transfer, and sign with key1 upon creating schedule transaction
        let receipt = try await TransferTransaction()
            .hbarTransfer(accountId, Hbar(-1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .schedule()
            .sign(key1)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let scheduleId = try XCTUnwrap(receipt.scheduleId)

        // Signature map is missing all required signatures
        await assertThrowsHErrorAsync(
            try await ScheduleSignTransaction()
                .scheduleId(scheduleId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error schedule sign"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .noNewValidSignatures)
        }

    }

    internal func testTokenMintSign() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account, initialSupply: 0)

        addTeardownBlock {
            try await token.delete(testEnv)
        }
        // Mint Token with signature
        let receipt = try await TokenMintTransaction()
            .tokenId(token.id)
            .sign(account.key)
            .schedule()
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let scheduleId = try XCTUnwrap(receipt.scheduleId)

        // Schedule Sign with account Private key
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)

        _ = try XCTUnwrap(info.executedAt)
    }
}
