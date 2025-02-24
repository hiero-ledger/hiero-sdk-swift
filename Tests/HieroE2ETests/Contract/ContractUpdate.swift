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
}
