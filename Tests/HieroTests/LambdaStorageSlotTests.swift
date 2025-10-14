// SPDX-License-Identifier: Apache-2.0

import XCTest
import Foundation
@testable import Hiero
import HieroProtobufs

final class LambdaStorageSlotUnitTests: XCTestCase {

    // Fixture-equivalent constants
    private let testKey   = Data([0x01, 0x23, 0x45])
    private let testValue = Data([0x67, 0x89, 0xAB])

    func test_GetSetKey() {
        // Given
        var slot = LambdaStorageSlot()

        // When
        slot.key(testKey)

        // Then
        XCTAssertEqual(slot.key, testKey)
    }

    func test_GetSetValue() {
        // Given
        var slot = LambdaStorageSlot()

        // When
        slot.value(testValue)

        // Then
        XCTAssertEqual(slot.value, testValue)
    }

    func test_FromProtobuf() throws {
        // Given
        var proto = Com_Hedera_Hapi_Node_Hooks_LambdaStorageSlot()
        proto.key = testKey
        proto.value = testValue

        // When
        let slot = try LambdaStorageSlot.fromProtobuf(proto)

        // Then
        XCTAssertEqual(slot.key, testKey)
        XCTAssertEqual(slot.value, testValue)
    }

    func test_ToProtobuf() {
        // Given
        var slot = LambdaStorageSlot()
        slot.key(testKey)
        slot.value(testValue)

        // When
        let proto = slot.toProtobuf()

        // Then
        XCTAssertEqual(proto.key, testKey)
        XCTAssertEqual(proto.value, testValue)
    }
}
