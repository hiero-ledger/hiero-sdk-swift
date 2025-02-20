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

import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenAllowanceTests: XCTestCase {

    private static let testSpenderAccountId = AccountId("0.2.24")

    private static func makeAllowance() -> TokenAllowance {
        TokenAllowance(
            tokenId: Resources.tokenId, ownerAccountId: Resources.accountId, spenderAccountId: testSpenderAccountId,
            amount: 4)
    }

    internal func testSerialize() throws {
        let allowance = Self.makeAllowance()

        assertSnapshot(matching: allowance, as: .description)
    }

    internal func testFromProtobuf() throws {
        let allowanceProto = Self.makeAllowance().toProtobuf()
        let allowance = try TokenAllowance.fromProtobuf(allowanceProto)

        assertSnapshot(matching: allowance, as: .description)
    }

    internal func testToProtobuf() throws {
        let allowanceProto = Self.makeAllowance().toProtobuf()

        assertSnapshot(matching: allowanceProto, as: .description)
    }
}
