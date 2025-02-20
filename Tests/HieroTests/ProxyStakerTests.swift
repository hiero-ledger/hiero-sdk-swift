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

internal final class ProxyStakerTests: XCTestCase {
    private static let proxyStaker: Proto_ProxyStaker = .with { proto in
        proto.accountID = Resources.accountId.toProtobuf()
        proto.amount = 10
    }

    internal func testFromProtobuf() throws {
        assertSnapshot(matching: try ProxyStaker.fromProtobuf(Self.proxyStaker), as: .description)
    }

    internal func testToProtobuf() throws {
        assertSnapshot(matching: try ProxyStaker.fromProtobuf(Self.proxyStaker).toProtobuf(), as: .description)
    }
}
