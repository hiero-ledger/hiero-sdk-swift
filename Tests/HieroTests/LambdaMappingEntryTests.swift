// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

final class LambdaMappingEntryUnitTests: XCTestCase {

    // Fixture-equivalent constants
    private let testKey = Data([0x01, 0x23, 0x45])
    private let testPreimage = Data([0x67, 0x89, 0xAB])
    private let testValue = Data([0xCD, 0xEF, 0x02])

    func test_GetSetKey() {
        // Given
        var entry = LambdaMappingEntry()

        // When
        entry.key(testKey)

        // Then
        XCTAssertNotNil(entry.key)
        XCTAssertEqual(entry.key, testKey)
    }

    func test_GetSetKeyResetPreimage() {
        // Given
        var entry = LambdaMappingEntry()

        // When
        entry.key(testKey)
        entry.preimage(testPreimage)

        // Then
        XCTAssertNil(entry.key)
    }

    func test_GetSetPreimage() {
        // Given
        var entry = LambdaMappingEntry()

        // When
        entry.preimage(testPreimage)

        // Then
        XCTAssertNotNil(entry.preimage)
        XCTAssertEqual(entry.preimage, testPreimage)
    }

    func test_GetSetPreimageResetsKey() {
        // Given
        var entry = LambdaMappingEntry()

        // When
        entry.preimage(testPreimage)
        entry.key(testKey)

        // Then
        XCTAssertNil(entry.preimage)
    }

    func test_GetSetValue() {
        // Given
        var entry = LambdaMappingEntry()

        // When
        entry.value(testValue)

        // Then
        XCTAssertEqual(entry.value, testValue)
    }

    func test_FromProtobuf() throws {
        // Given
        var protoKey = Com_Hedera_Hapi_Node_Hooks_LambdaMappingEntry()
        var protoPreimage = Com_Hedera_Hapi_Node_Hooks_LambdaMappingEntry()

        protoKey.key = testKey
        protoKey.value = testValue

        protoPreimage.preimage = testPreimage

        // When
        let entryKey = try LambdaMappingEntry.fromProtobuf(protoKey)
        let entryPreimage = try LambdaMappingEntry.fromProtobuf(protoPreimage)

        // Then
        XCTAssertNotNil(entryKey.key)
        XCTAssertEqual(entryKey.key, testKey)
        XCTAssertEqual(entryKey.value, testValue)

        XCTAssertNotNil(entryPreimage.preimage)
        XCTAssertEqual(entryPreimage.preimage, testPreimage)
    }

    func test_ToProtobuf() {
        // Given
        var entryKey = LambdaMappingEntry()
        var entryPreimage = LambdaMappingEntry()

        entryKey.key(testKey)
        entryKey.value(testValue)

        entryPreimage.preimage(testPreimage)

        // When
        let protoKey = entryKey.toProtobuf()
        let protoPreimage = entryPreimage.toProtobuf()

        // Then
        // key path
        XCTAssertEqual(protoKey.key, testKey)
        XCTAssertEqual(protoKey.value, testValue)

        // preimage path
        XCTAssertEqual(protoPreimage.preimage, testPreimage)
    }
}
