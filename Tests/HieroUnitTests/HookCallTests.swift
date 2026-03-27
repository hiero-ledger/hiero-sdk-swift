// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

internal final class HookCallUnitTests: XCTestCase {

    private let testHookId: Int64 = 4
    private let testCallData = Data([0x56, 0x78, 0x9A])
    private let testGasLimit: UInt64 = 11

    private var testEvmHookCall: EvmHookCall {
        var c = EvmHookCall()
        c.data = testCallData
        c.gasLimit = testGasLimit
        return c
    }

    internal func test_GetSetHookId() {
        var hookCall = HookCall()

        hookCall.hookId(testHookId)

        XCTAssertEqual(hookCall.hookId, testHookId)
    }

    internal func test_GetSetEvmHookCall() {
        var hookCall = HookCall()

        hookCall.evmHookCall(testEvmHookCall)

        XCTAssertNotNil(hookCall.evmHookCall)
        XCTAssertEqual(hookCall.evmHookCall?.data, testCallData)
        XCTAssertEqual(hookCall.evmHookCall?.gasLimit, testGasLimit)
    }

    internal func test_FromProtobuf() throws {
        var protoWithEvmCall = Proto_HookCall()
        var protoHookIdOnly = Proto_HookCall()

        protoWithEvmCall.hookID = testHookId
        protoWithEvmCall.evmHookCall = testEvmHookCall.toProtobuf()

        protoHookIdOnly.hookID = testHookId

        let hookCallWithEvm = try HookCall.fromProtobuf(protoWithEvmCall)
        let hookCallHookOnly = try HookCall.fromProtobuf(protoHookIdOnly)

        XCTAssertEqual(hookCallWithEvm.hookId, testHookId)
        XCTAssertNotNil(hookCallWithEvm.evmHookCall)
        XCTAssertEqual(hookCallWithEvm.evmHookCall?.data, testCallData)
        XCTAssertEqual(hookCallWithEvm.evmHookCall?.gasLimit, testGasLimit)

        XCTAssertEqual(hookCallHookOnly.hookId, testHookId)
    }

    internal func test_ToProtobuf() {
        var hookCallWithEvm = HookCall()
        var hookCallHookOnly = HookCall()

        hookCallWithEvm.hookId = testHookId
        hookCallWithEvm.evmHookCall = testEvmHookCall

        hookCallHookOnly.hookId = testHookId

        let protoWithEvm = hookCallWithEvm.toProtobuf()
        let protoHookOnly = hookCallHookOnly.toProtobuf()

        XCTAssertEqual(protoWithEvm.hookID, testHookId)
        XCTAssertEqual(protoWithEvm.evmHookCall.data, testCallData)
        XCTAssertEqual(protoWithEvm.evmHookCall.gasLimit, testGasLimit)

        XCTAssertEqual(protoHookOnly.hookID, testHookId)
    }
}
