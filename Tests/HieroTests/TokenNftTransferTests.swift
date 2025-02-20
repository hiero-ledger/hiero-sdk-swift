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

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal class TokenNftTransferTests: XCTestCase {
    internal static let testReceiver = AccountId("0.0.5008")
    internal static let testSerialNumber = 4

    private func makeTransfer() throws -> TokenNftTransfer {
        TokenNftTransfer.init(
            tokenId: Resources.tokenId, sender: Resources.accountId, receiver: Self.testReceiver, serial: 4,
            isApproved: true)
    }

    internal func testSerialize() throws {
        let transfer = try makeTransfer()

        assertSnapshot(of: transfer, as: .description)
    }
}
