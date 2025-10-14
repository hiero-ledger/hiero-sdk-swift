// SPDX-License-Identifier: Apache-2.0

import XCTest
import Foundation
@testable import Hiero 
import HieroProtobufs

final class HookCallUnitTests: XCTestCase {

    // Fixture-equivalent constants
    private let testAccountId = AccountId(shard: 1, realm: 2, num: 3)
    private let testHookId: Int64 = 4
    private let testCallData = Data([0x56, 0x78, 0x9A])
    private let testGasLimit: UInt64 = 11

    private var testHookEntityId: HookEntityId {
        return HookEntityId(testAccountId)
    }

    private var testFullHookId: HookId {
        return HookId(entityId: testHookEntityId, hookId: testHookId)
    }

    private var testEvmHookCall: EvmHookCall {
        var c = EvmHookCall()
        c.data = testCallData
        c.gasLimit = testGasLimit
        return c
    }

    func test_GetSetFullHookId() {
        // Given
        var hookCall = HookCall()

        // When
        hookCall.fullHookId(testFullHookId)

        // Then
        XCTAssertNotNil(hookCall.fullHookId?.entityId.accountId)
        XCTAssertEqual(hookCall.fullHookId?.entityId.accountId, testAccountId)
        XCTAssertEqual(hookCall.fullHookId?.hookId, testHookId)
    }

    func test_GetSetFullHookIdResetsHookId() {
        // Given
        var hookCall = HookCall()

        // When
        hookCall.hookId(testHookId)
        hookCall.fullHookId(testFullHookId)

        // Then
        XCTAssertNil(hookCall.hookId)
    }

    func test_GetSetHookId() {
        // Given
        var hookCall = HookCall()

        // When
        hookCall.hookId(testHookId)

        // Then
        XCTAssertEqual(hookCall.hookId, testHookId)
    }

    func test_GetSetHookIdResetsFullHookId() {
        // Given
        var hookCall = HookCall()

        // When
        hookCall.fullHookId(testFullHookId)
        hookCall.hookId(testHookId)

        // Then
        XCTAssertNil(hookCall.fullHookId)
    }

    func test_GetSetEvmHookCall() {
        // Given
        var hookCall = HookCall()

        // When
        hookCall.evmHookCall(testEvmHookCall)

        // Then
        XCTAssertNotNil(hookCall.evmHookCall)
        XCTAssertEqual(hookCall.evmHookCall?.data, testCallData)
        XCTAssertEqual(hookCall.evmHookCall?.gasLimit, testGasLimit)
    }

    func test_FromProtobuf() throws {
        // Given
        var protoFull = Proto_HookCall()
        var protoHookIdOnly = Proto_HookCall()

        // full_hook_id + evm_hook_call
        protoFull.fullHookID = testFullHookId.toProtobuf()
        protoFull.evmHookCall = testEvmHookCall.toProtobuf()

        // hook_id only
        protoHookIdOnly.hookID = testHookId

        // When
        let hookCallFull = try HookCall.fromProtobuf(protoFull)
        let hookCallHookOnly = try HookCall.fromProtobuf(protoHookIdOnly)

        // Then
        XCTAssertNotNil(hookCallFull.fullHookId?.entityId.accountId)
        XCTAssertEqual(hookCallFull.fullHookId?.entityId.accountId, testAccountId)
        XCTAssertEqual(hookCallFull.fullHookId?.hookId, testHookId)

        XCTAssertNotNil(hookCallFull.evmHookCall)
        XCTAssertEqual(hookCallFull.evmHookCall?.data, testCallData)
        XCTAssertEqual(hookCallFull.evmHookCall?.gasLimit, testGasLimit)

        XCTAssertEqual(hookCallHookOnly.hookId, testHookId)
    }

    func test_ToProtobuf() {
        // Given
        var hookCallFull = HookCall()
        var hookCallHookOnly = HookCall()

        hookCallFull.fullHookId = testFullHookId
        hookCallFull.evmHookCall = testEvmHookCall

        hookCallHookOnly.hookId = testHookId

        // When
        let protoFull = hookCallFull.toProtobuf()
        let protoHookOnly = hookCallHookOnly.toProtobuf()

        // Then
        XCTAssertTrue(protoFull.fullHookID.hasEntityID)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoFull.fullHookID.entityID.accountID.shardNum), testAccountId.shard)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoFull.fullHookID.entityID.accountID.realmNum), testAccountId.realm)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoFull.fullHookID.entityID.accountID.accountNum), testAccountId.num)
        XCTAssertEqual(protoFull.fullHookID.hookID, testHookId)

        XCTAssertEqual(protoFull.evmHookCall.data, testCallData)
        XCTAssertEqual(protoFull.evmHookCall.gasLimit, testGasLimit)

        XCTAssertEqual(protoHookOnly.hookID, testHookId)
    }
}
