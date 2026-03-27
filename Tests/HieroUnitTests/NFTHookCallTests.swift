// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

internal final class NFTHookCallUnitTests: XCTestCase {

    private let testHookId: Int64 = 4
    private let testCallData = Data([0x56, 0x78, 0x9A])
    private let testGasLimit: UInt64 = 11

    private var testEvmHookCall: EvmHookCall {
        var c = EvmHookCall()
        c.data = testCallData
        c.gasLimit = testGasLimit
        return c
    }

    internal func test_DefaultInitialization() {
        let nftHookCall = NftHookCall()

        XCTAssertEqual(nftHookCall.hookType, .uninitialized)
        XCTAssertNil(nftHookCall.hookCall.hookId)
        XCTAssertNil(nftHookCall.hookCall.evmHookCall)
    }

    internal func test_CustomInitialization() {
        let hookCall = HookCall()
        let hookType = NftHookType.preHook

        let nftHookCall = NftHookCall(hookCall: hookCall, hookType: hookType)

        XCTAssertEqual(nftHookCall.hookType, hookType)
        XCTAssertNil(nftHookCall.hookCall.hookId)
        XCTAssertNil(nftHookCall.hookCall.evmHookCall)
    }

    internal func test_SetHookCall() {
        var nftHookCall = NftHookCall()
        let hookCall = HookCall()

        nftHookCall.hookCall(hookCall)

        XCTAssertNil(nftHookCall.hookCall.hookId)
        XCTAssertNil(nftHookCall.hookCall.evmHookCall)
    }

    internal func test_SetHookType() {
        var nftHookCall = NftHookCall()

        nftHookCall.hookType(.preHook)

        XCTAssertEqual(nftHookCall.hookType, .preHook)
    }

    internal func test_SetHookId() {
        var nftHookCall = NftHookCall()

        nftHookCall.hookId(testHookId)

        XCTAssertEqual(nftHookCall.hookCall.hookId, testHookId)
    }

    internal func test_SetEvmHookCall() {
        var nftHookCall = NftHookCall()

        nftHookCall.evmHookCall(testEvmHookCall)

        XCTAssertNotNil(nftHookCall.hookCall.evmHookCall)
        XCTAssertEqual(nftHookCall.hookCall.evmHookCall?.data, testCallData)
        XCTAssertEqual(nftHookCall.hookCall.evmHookCall?.gasLimit, testGasLimit)
    }

    internal func test_FromProtobuf() throws {
        var proto = Proto_HookCall()
        proto.hookID = testHookId
        proto.evmHookCall = testEvmHookCall.toProtobuf()

        let nftHookCall = try NftHookCall.fromProtobuf(proto)

        XCTAssertEqual(nftHookCall.hookCall.hookId, testHookId)
        XCTAssertNotNil(nftHookCall.hookCall.evmHookCall)
        XCTAssertEqual(nftHookCall.hookCall.evmHookCall?.data, testCallData)
        XCTAssertEqual(nftHookCall.hookCall.evmHookCall?.gasLimit, testGasLimit)
        XCTAssertEqual(nftHookCall.hookType, .uninitialized)
    }

    internal func test_ToProtobuf() {
        var nftHookCall = NftHookCall()
        nftHookCall.hookCall.hookId = testHookId
        nftHookCall.hookCall.evmHookCall = testEvmHookCall
        nftHookCall.hookType = .preHook

        let proto = nftHookCall.toProtobuf()

        XCTAssertEqual(proto.hookID, testHookId)
        XCTAssertEqual(proto.evmHookCall.data, testCallData)
        XCTAssertEqual(proto.evmHookCall.gasLimit, testGasLimit)
    }
}
