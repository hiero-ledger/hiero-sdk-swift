// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

internal final class FungibleHookCallUnitTests: XCTestCase {

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
        let fungibleHookCall = FungibleHookCall()

        XCTAssertEqual(fungibleHookCall.hookType, .uninitialized)
        XCTAssertNil(fungibleHookCall.hookCall.hookId)
        XCTAssertNil(fungibleHookCall.hookCall.evmHookCall)
    }

    internal func test_CustomInitialization() {
        let hookCall = HookCall()
        let hookType = FungibleHookType.preHookSender

        let fungibleHookCall = FungibleHookCall(hookCall: hookCall, hookType: hookType)

        XCTAssertEqual(fungibleHookCall.hookType, hookType)
        XCTAssertNil(fungibleHookCall.hookCall.hookId)
        XCTAssertNil(fungibleHookCall.hookCall.evmHookCall)
    }

    internal func test_SetHookCall() {
        var fungibleHookCall = FungibleHookCall()
        let hookCall = HookCall()

        fungibleHookCall.hookCall(hookCall)

        XCTAssertNil(fungibleHookCall.hookCall.hookId)
        XCTAssertNil(fungibleHookCall.hookCall.evmHookCall)
    }

    internal func test_SetHookType() {
        var fungibleHookCall = FungibleHookCall()

        fungibleHookCall.hookType(.preHookSender)

        XCTAssertEqual(fungibleHookCall.hookType, .preHookSender)
    }

    internal func test_SetHookId() {
        var fungibleHookCall = FungibleHookCall()

        fungibleHookCall.hookId(testHookId)

        XCTAssertEqual(fungibleHookCall.hookCall.hookId, testHookId)
    }

    internal func test_SetEvmHookCall() {
        var fungibleHookCall = FungibleHookCall()

        fungibleHookCall.evmHookCall(testEvmHookCall)

        XCTAssertNotNil(fungibleHookCall.hookCall.evmHookCall)
        XCTAssertEqual(fungibleHookCall.hookCall.evmHookCall?.data, testCallData)
        XCTAssertEqual(fungibleHookCall.hookCall.evmHookCall?.gasLimit, testGasLimit)
    }

    internal func test_FromProtobuf() throws {
        var proto = Proto_HookCall()
        proto.hookID = testHookId
        proto.evmHookCall = testEvmHookCall.toProtobuf()

        let fungibleHookCall = try FungibleHookCall.fromProtobuf(proto)

        XCTAssertEqual(fungibleHookCall.hookCall.hookId, testHookId)
        XCTAssertNotNil(fungibleHookCall.hookCall.evmHookCall)
        XCTAssertEqual(fungibleHookCall.hookCall.evmHookCall?.data, testCallData)
        XCTAssertEqual(fungibleHookCall.hookCall.evmHookCall?.gasLimit, testGasLimit)
        XCTAssertEqual(fungibleHookCall.hookType, .uninitialized)
    }

    internal func test_ToProtobuf() {
        var fungibleHookCall = FungibleHookCall()
        fungibleHookCall.hookCall.hookId = testHookId
        fungibleHookCall.hookCall.evmHookCall = testEvmHookCall
        fungibleHookCall.hookType = .preHookSender

        let proto = fungibleHookCall.toProtobuf()

        XCTAssertEqual(proto.hookID, testHookId)
        XCTAssertEqual(proto.evmHookCall.data, testCallData)
        XCTAssertEqual(proto.evmHookCall.gasLimit, testGasLimit)
    }
}
