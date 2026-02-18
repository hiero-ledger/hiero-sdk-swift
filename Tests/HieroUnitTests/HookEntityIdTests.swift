// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import XCTest

@testable import Hiero  // TODO: Replace with your Swift target/module name

final class HookEntityIdUnitTests: XCTestCase {

    private let testAccountId = AccountId(shard: 1, realm: 2, num: 3)

    func test_GetSetAccountId() {
        // Given
        let hookEntityId = HookEntityId(AccountId(num: 0))

        // When
        hookEntityId.accountId(testAccountId)

        // Then
        XCTAssertEqual(hookEntityId.accountId, testAccountId)
    }

    func test_FromProtobuf() throws {
        // Given
        var protoMsg = Proto_HookEntityId()
        protoMsg.accountID = testAccountId.toProtobuf()

        // When
        let hookEntityId = try HookEntityId.fromProtobuf(protoMsg)

        // Then
        XCTAssertEqual(hookEntityId.accountId, testAccountId)
    }

    func test_ToProtobuf() {
        // Given
        let hookEntityId = HookEntityId(testAccountId)

        // When
        let protoMsg = hookEntityId.toProtobuf()

        // Then
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoMsg.accountID.shardNum), testAccountId.shard)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoMsg.accountID.realmNum), testAccountId.realm)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoMsg.accountID.accountNum), testAccountId.num)
    }
}
