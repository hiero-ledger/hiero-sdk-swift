// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class ScheduleDelete: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv, balance: 1)

        let receipt = try await TransferTransaction()
            .hbarTransfer(account.id, Hbar(-1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .schedule()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let scheduleId = try XCTUnwrap(receipt.scheduleId)

        _ = try await ScheduleDeleteTransaction(scheduleId: scheduleId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testMissingAdminKeyFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv, balance: 1)

        let receipt = try await TransferTransaction()
            .hbarTransfer(account.id, Hbar(-1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .schedule()
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let scheduleId = try XCTUnwrap(receipt.scheduleId)

        await assertThrowsHErrorAsync(
            try await ScheduleDeleteTransaction(scheduleId: scheduleId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .scheduleIsImmutable)
        }
    }

    internal func testDoubleDeleteFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv, balance: 1)

        let receipt = try await TransferTransaction()
            .hbarTransfer(account.id, Hbar(-1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .schedule()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let scheduleId = try XCTUnwrap(receipt.scheduleId)

        _ = try await ScheduleDeleteTransaction(scheduleId: scheduleId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            try await ScheduleDeleteTransaction(scheduleId: scheduleId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .scheduleAlreadyDeleted)
        }
    }

    internal func testMissingScheduleIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await ScheduleDeleteTransaction()
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidScheduleID)
        }
    }
}
