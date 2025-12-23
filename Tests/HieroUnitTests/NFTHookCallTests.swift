// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

final class NFTHookCallUnitTests: XCTestCase {

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
        let nftHookCall = NftHookCall()

        // Then
        XCTAssertEqual(nftHookCall.hookType, .uninitialized)
        XCTAssertNil(nftHookCall.hookCall.fullHookId)
        XCTAssertNil(nftHookCall.hookCall.hookId)
        XCTAssertNil(nftHookCall.hookCall.evmHookCall)
    }

    func test_CustomInitialization() {
        // Given
        let hookCall = HookCall()
        let hookType = NftHookType.preHook

        // When
        let nftHookCall = NftHookCall(hookCall: hookCall, hookType: hookType)

        // Then
        XCTAssertEqual(nftHookCall.hookType, hookType)
        XCTAssertNil(nftHookCall.hookCall.fullHookId)
        XCTAssertNil(nftHookCall.hookCall.hookId)
        XCTAssertNil(nftHookCall.hookCall.evmHookCall)
    }

    func test_SetHookCall() {
        // Given
        var nftHookCall = NftHookCall()
        let hookCall = HookCall()

        // When
        nftHookCall.hookCall(hookCall)

        // Then
        XCTAssertNil(nftHookCall.hookCall.fullHookId)
        XCTAssertNil(nftHookCall.hookCall.hookId)
        XCTAssertNil(nftHookCall.hookCall.evmHookCall)
    }

    func test_SetHookType() {
        // Given
        var nftHookCall = NftHookCall()

        // When
        nftHookCall.hookType(.preHook)

        // Then
        XCTAssertEqual(nftHookCall.hookType, .preHook)
    }

    func test_SetFullHookId() {
        // Given
        var nftHookCall = NftHookCall()

        // When
        nftHookCall.fullHookId(testFullHookId)

        // Then
        XCTAssertNotNil(nftHookCall.hookCall.fullHookId?.entityId.accountId)
        XCTAssertEqual(nftHookCall.hookCall.fullHookId?.entityId.accountId, testAccountId)
        XCTAssertEqual(nftHookCall.hookCall.fullHookId?.hookId, testHookId)
    }

    func test_SetHookId() {
        // Given
        var nftHookCall = NftHookCall()

        // When
        nftHookCall.hookId(testHookId)

        // Then
        XCTAssertEqual(nftHookCall.hookCall.hookId, testHookId)
    }

    func test_SetEvmHookCall() {
        // Given
        var nftHookCall = NftHookCall()

        // When
        nftHookCall.evmHookCall(testEvmHookCall)

        // Then
        XCTAssertNotNil(nftHookCall.hookCall.evmHookCall)
        XCTAssertEqual(nftHookCall.hookCall.evmHookCall?.data, testCallData)
        XCTAssertEqual(nftHookCall.hookCall.evmHookCall?.gasLimit, testGasLimit)
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
        let nftHookCallFull = try NftHookCall.fromProtobuf(protoFull)
        let nftHookCallHookOnly = try NftHookCall.fromProtobuf(protoHookIdOnly)

        // Then
        XCTAssertNotNil(nftHookCallFull.hookCall.fullHookId?.entityId.accountId)
        XCTAssertEqual(nftHookCallFull.hookCall.fullHookId?.entityId.accountId, testAccountId)
        XCTAssertEqual(nftHookCallFull.hookCall.fullHookId?.hookId, testHookId)

        XCTAssertNotNil(nftHookCallFull.hookCall.evmHookCall)
        XCTAssertEqual(nftHookCallFull.hookCall.evmHookCall?.data, testCallData)
        XCTAssertEqual(nftHookCallFull.hookCall.evmHookCall?.gasLimit, testGasLimit)

        XCTAssertEqual(nftHookCallHookOnly.hookCall.hookId, testHookId)

        // Hook type should be uninitialized since it's not stored in protobuf
        XCTAssertEqual(nftHookCallFull.hookType, .uninitialized)
        XCTAssertEqual(nftHookCallHookOnly.hookType, .uninitialized)
    }

    func test_ToProtobuf() {
        // Given
        var nftHookCallFull = NftHookCall()
        var nftHookCallHookOnly = NftHookCall()

        nftHookCallFull.hookCall.fullHookId = testFullHookId
        nftHookCallFull.hookCall.evmHookCall = testEvmHookCall
        nftHookCallFull.hookType = .preHook

        nftHookCallHookOnly.hookCall.hookId = testHookId
        nftHookCallHookOnly.hookType = .prePostHook

        // When
        let protoFull = nftHookCallFull.toProtobuf()
        let protoHookOnly = nftHookCallHookOnly.toProtobuf()

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
