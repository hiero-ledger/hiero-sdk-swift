// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

internal final class EvmHookStorageSlotUnitTests: XCTestCase {

    private let testKey = Data([0x01, 0x23, 0x45])
    private let testValue = Data([0x67, 0x89, 0xAB])

    internal func test_GetSetKey() {
        var slot = EvmHookStorageSlot()

        slot.key(testKey)

        XCTAssertEqual(slot.key, testKey)
    }

    internal func test_GetSetValue() {
        var slot = EvmHookStorageSlot()

        slot.value(testValue)

        XCTAssertEqual(slot.value, testValue)
    }

    internal func test_FromProtobuf() throws {
        var proto = Com_Hedera_Hapi_Node_Hooks_EvmHookStorageSlot()
        proto.key = testKey
        proto.value = testValue

        let slot = try EvmHookStorageSlot.fromProtobuf(proto)

        XCTAssertEqual(slot.key, testKey)
        XCTAssertEqual(slot.value, testValue)
    }

    internal func test_ToProtobuf() {
        var slot = EvmHookStorageSlot()
        slot.key(testKey)
        slot.value(testValue)

        let proto = slot.toProtobuf()

        XCTAssertEqual(proto.key, testKey)
        XCTAssertEqual(proto.value, testValue)
    }
}
