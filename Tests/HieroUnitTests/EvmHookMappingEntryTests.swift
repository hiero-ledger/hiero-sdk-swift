// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

internal final class EvmHookMappingEntryUnitTests: XCTestCase {

    private let testKey = Data([0x01, 0x23, 0x45])
    private let testPreimage = Data([0x67, 0x89, 0xAB])
    private let testValue = Data([0xCD, 0xEF, 0x02])

    internal func test_GetSetKey() {
        var entry = EvmHookMappingEntry()

        entry.key(testKey)

        XCTAssertNotNil(entry.key)
        XCTAssertEqual(entry.key, testKey)
    }

    internal func test_GetSetKeyResetPreimage() {
        var entry = EvmHookMappingEntry()

        entry.key(testKey)
        entry.preimage(testPreimage)

        XCTAssertNil(entry.key)
    }

    internal func test_GetSetPreimage() {
        var entry = EvmHookMappingEntry()

        entry.preimage(testPreimage)

        XCTAssertNotNil(entry.preimage)
        XCTAssertEqual(entry.preimage, testPreimage)
    }

    internal func test_GetSetPreimageResetsKey() {
        var entry = EvmHookMappingEntry()

        entry.preimage(testPreimage)
        entry.key(testKey)

        XCTAssertNil(entry.preimage)
    }

    internal func test_GetSetValue() {
        var entry = EvmHookMappingEntry()

        entry.value(testValue)

        XCTAssertEqual(entry.value, testValue)
    }

    internal func test_FromProtobuf() throws {
        var protoKey = Com_Hedera_Hapi_Node_Hooks_EvmHookMappingEntry()
        var protoPreimage = Com_Hedera_Hapi_Node_Hooks_EvmHookMappingEntry()

        protoKey.key = testKey
        protoKey.value = testValue

        protoPreimage.preimage = testPreimage

        let entryKey = try EvmHookMappingEntry.fromProtobuf(protoKey)
        let entryPreimage = try EvmHookMappingEntry.fromProtobuf(protoPreimage)

        XCTAssertNotNil(entryKey.key)
        XCTAssertEqual(entryKey.key, testKey)
        XCTAssertEqual(entryKey.value, testValue)

        XCTAssertNotNil(entryPreimage.preimage)
        XCTAssertEqual(entryPreimage.preimage, testPreimage)
    }

    internal func test_ToProtobuf() {
        var entryKey = EvmHookMappingEntry()
        var entryPreimage = EvmHookMappingEntry()

        entryKey.key(testKey)
        entryKey.value(testValue)

        entryPreimage.preimage(testPreimage)

        let protoKey = entryKey.toProtobuf()
        let protoPreimage = entryPreimage.toProtobuf()

        XCTAssertEqual(protoKey.key, testKey)
        XCTAssertEqual(protoKey.value, testValue)

        XCTAssertEqual(protoPreimage.preimage, testPreimage)
    }
}
