// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import XCTest

@testable import Hiero

final class HookIdUnitTests: XCTestCase {

    private let testAccountId = AccountId(shard: 1, realm: 2, num: 3)
    private let testHookId: Int64 = 4
    private var testHookEntityId: HookEntityId {
        return HookEntityId(testAccountId)
    }

    func test_GetSetEntityId() {
        // Given
        var hookId = HookId()

        // When
        hookId.entityId(testHookEntityId)

        // Then
        XCTAssertNotNil(hookId.entityId.accountId)
        XCTAssertEqual(hookId.entityId.accountId, testAccountId)
    }

    func test_GetSetHookId() {
        // Given
        var hookId = HookId()

        // When
        hookId.hookId(testHookId)

        // Then
        XCTAssertEqual(hookId.hookId, testHookId)
    }

    func test_FromProtobuf() throws {
        // Given
        var proto = Proto_HookId()
        proto.entityID = testHookEntityId.toProtobuf()
        proto.hookID = testHookId

        // When
        let hookId = try HookId.fromProtobuf(proto)

        // Then
        XCTAssertNotNil(hookId.entityId.accountId)
        XCTAssertEqual(hookId.entityId.accountId, testAccountId)
        XCTAssertEqual(hookId.hookId, testHookId)
    }

    func test_ToProtobuf() {
        // Given
        let hookId = HookId(entityId: testHookEntityId, hookId: testHookId)

        // When
        let proto = hookId.toProtobuf()

        // Then
        XCTAssertTrue(proto.hasEntityID)
        XCTAssertEqual(UInt64(truncatingIfNeeded: proto.entityID.accountID.shardNum), testAccountId.shard)
        XCTAssertEqual(UInt64(truncatingIfNeeded: proto.entityID.accountID.realmNum), testAccountId.realm)
        XCTAssertEqual(UInt64(truncatingIfNeeded: proto.entityID.accountID.accountNum), testAccountId.num)
    }
}
