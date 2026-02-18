// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

final class FungibleHookCallUnitTests: XCTestCase {

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

    func test_DefaultInitialization() {
        // Given & When
        let fungibleHookCall = FungibleHookCall()

        // Then
        XCTAssertEqual(fungibleHookCall.hookType, .uninitialized)
        XCTAssertNil(fungibleHookCall.hookCall.fullHookId)
        XCTAssertNil(fungibleHookCall.hookCall.hookId)
        XCTAssertNil(fungibleHookCall.hookCall.evmHookCall)
    }

    func test_CustomInitialization() {
        // Given
        let hookCall = HookCall()
        let hookType = FungibleHookType.preTxAllowanceHook

        // When
        let fungibleHookCall = FungibleHookCall(hookCall: hookCall, hookType: hookType)

        // Then
        XCTAssertEqual(fungibleHookCall.hookType, hookType)
        XCTAssertNil(fungibleHookCall.hookCall.fullHookId)
        XCTAssertNil(fungibleHookCall.hookCall.hookId)
        XCTAssertNil(fungibleHookCall.hookCall.evmHookCall)
    }

    func test_SetHookCall() {
        // Given
        var fungibleHookCall = FungibleHookCall()
        let hookCall = HookCall()

        // When
        fungibleHookCall.hookCall(hookCall)

        // Then
        XCTAssertNil(fungibleHookCall.hookCall.fullHookId)
        XCTAssertNil(fungibleHookCall.hookCall.hookId)
        XCTAssertNil(fungibleHookCall.hookCall.evmHookCall)
    }

    func test_SetHookType() {
        // Given
        var fungibleHookCall = FungibleHookCall()

        // When
        fungibleHookCall.hookType(.preTxAllowanceHook)

        // Then
        XCTAssertEqual(fungibleHookCall.hookType, .preTxAllowanceHook)
    }

    func test_SetFullHookId() {
        // Given
        var fungibleHookCall = FungibleHookCall()

        // When
        fungibleHookCall.fullHookId(testFullHookId)

        // Then
        XCTAssertNotNil(fungibleHookCall.hookCall.fullHookId?.entityId.accountId)
        XCTAssertEqual(fungibleHookCall.hookCall.fullHookId?.entityId.accountId, testAccountId)
        XCTAssertEqual(fungibleHookCall.hookCall.fullHookId?.hookId, testHookId)
    }

    func test_SetHookId() {
        // Given
        var fungibleHookCall = FungibleHookCall()

        // When
        fungibleHookCall.hookId(testHookId)

        // Then
        XCTAssertEqual(fungibleHookCall.hookCall.hookId, testHookId)
    }

    func test_SetEvmHookCall() {
        // Given
        var fungibleHookCall = FungibleHookCall()

        // When
        fungibleHookCall.evmHookCall(testEvmHookCall)

        // Then
        XCTAssertNotNil(fungibleHookCall.hookCall.evmHookCall)
        XCTAssertEqual(fungibleHookCall.hookCall.evmHookCall?.data, testCallData)
        XCTAssertEqual(fungibleHookCall.hookCall.evmHookCall?.gasLimit, testGasLimit)
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
        let fungibleHookCallFull = try FungibleHookCall.fromProtobuf(protoFull)
        let fungibleHookCallHookOnly = try FungibleHookCall.fromProtobuf(protoHookIdOnly)

        // Then
        XCTAssertNotNil(fungibleHookCallFull.hookCall.fullHookId?.entityId.accountId)
        XCTAssertEqual(fungibleHookCallFull.hookCall.fullHookId?.entityId.accountId, testAccountId)
        XCTAssertEqual(fungibleHookCallFull.hookCall.fullHookId?.hookId, testHookId)

        XCTAssertNotNil(fungibleHookCallFull.hookCall.evmHookCall)
        XCTAssertEqual(fungibleHookCallFull.hookCall.evmHookCall?.data, testCallData)
        XCTAssertEqual(fungibleHookCallFull.hookCall.evmHookCall?.gasLimit, testGasLimit)

        XCTAssertEqual(fungibleHookCallHookOnly.hookCall.hookId, testHookId)

        // Hook type should be uninitialized since it's not stored in protobuf
        XCTAssertEqual(fungibleHookCallFull.hookType, .uninitialized)
        XCTAssertEqual(fungibleHookCallHookOnly.hookType, .uninitialized)
    }

    func test_ToProtobuf() {
        // Given
        var fungibleHookCallFull = FungibleHookCall()
        var fungibleHookCallHookOnly = FungibleHookCall()

        fungibleHookCallFull.hookCall.fullHookId = testFullHookId
        fungibleHookCallFull.hookCall.evmHookCall = testEvmHookCall
        fungibleHookCallFull.hookType = .preTxAllowanceHook

        fungibleHookCallHookOnly.hookCall.hookId = testHookId
        fungibleHookCallHookOnly.hookType = .prePostTxAllowanceHook

        // When
        let protoFull = fungibleHookCallFull.toProtobuf()
        let protoHookOnly = fungibleHookCallHookOnly.toProtobuf()

        // Then
        XCTAssertTrue(protoFull.fullHookID.hasEntityID)
        XCTAssertEqual(
            UInt64(truncatingIfNeeded: protoFull.fullHookID.entityID.accountID.shardNum), testAccountId.shard)
        XCTAssertEqual(
            UInt64(truncatingIfNeeded: protoFull.fullHookID.entityID.accountID.realmNum), testAccountId.realm)
        XCTAssertEqual(
            UInt64(truncatingIfNeeded: protoFull.fullHookID.entityID.accountID.accountNum), testAccountId.num)
        XCTAssertEqual(protoFull.fullHookID.hookID, testHookId)

        XCTAssertEqual(protoFull.evmHookCall.data, testCallData)
        XCTAssertEqual(protoFull.evmHookCall.gasLimit, testGasLimit)

        XCTAssertEqual(protoHookOnly.hookID, testHookId)
    }
}
