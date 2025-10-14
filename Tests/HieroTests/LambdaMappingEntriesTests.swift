// SPDX-License-Identifier: Apache-2.0

import XCTest
import Foundation
@testable import Hiero
import HieroProtobufs

final class LambdaMappingEntriesUnitTests: XCTestCase {

    // Fixture-equivalent constants
    private let mappingSlot = Data([0x17, 0x19, 0x1B])

    private let key1      = Data([0x01, 0x23, 0x45])
    private let key3      = Data([0x67, 0x89, 0xAB])
    private let preimage2 = Data([0xCD, 0xEF, 0x02])

    private let value1 = Data([0x04, 0x06, 0x08])
    private let value2 = Data([0x0A, 0x0C, 0x0E])
    private let value3 = Data([0x11, 0x13, 0x15])

    private func makeEntry1() -> LambdaMappingEntry {
        var e = LambdaMappingEntry()
        e.key(key1)
        e.value(value1)
        return e
    }

    private func makeEntry2() -> LambdaMappingEntry {
        var e = LambdaMappingEntry()
        e.preimage(preimage2)
        e.value(value2)
        return e
    }

    private func makeEntry3() -> LambdaMappingEntry {
        var e = LambdaMappingEntry()
        e.key(key3)
        e.value(value3)
        return e
    }

    private func makeEntries() -> [LambdaMappingEntry] {
        [makeEntry1(), makeEntry2(), makeEntry3()]
    }

    func test_GetSetMappingSlot() {
        // Given
        var entries = LambdaMappingEntries()

        // When
        entries.mappingSlot(mappingSlot)

        // Then
        XCTAssertEqual(entries.mappingSlot, mappingSlot)
    }

    func test_GetSetEntries() {
        // Given
        var entries = LambdaMappingEntries()

        // When
        entries.setEntries(makeEntries())

        // Then
        XCTAssertEqual(entries.entries.count, makeEntries().count)
    }

    func test_AddEntry() {
        // Given
        var entries = LambdaMappingEntries()
        let e1 = makeEntry1()

        // When
        entries.addEntry(e1)

        // Then
        XCTAssertEqual(entries.entries.count, 1)
        XCTAssertNotNil(entries.entries[0].key)
        XCTAssertEqual(entries.entries[0].key, key1)
        XCTAssertEqual(entries.entries[0].value, value1)
    }

    func test_ClearEntries() {
        // Given
        var entries = LambdaMappingEntries()
        entries.setEntries(makeEntries())

        // When
        entries.clearEntries()

        // Then
        XCTAssertTrue(entries.entries.isEmpty)
    }

    func test_FromProtobuf() throws {
        // Given
        var proto = Com_Hedera_Hapi_Node_Hooks_LambdaMappingEntries()
        proto.mappingSlot = mappingSlot
        proto.entries = makeEntries().map { $0.toProtobuf() }

        // When
        let decoded = try LambdaMappingEntries.fromProtobuf(proto)

        // Then
        XCTAssertEqual(decoded.mappingSlot, mappingSlot)
        XCTAssertEqual(decoded.entries.count, makeEntries().count)
    }

    func test_ToProtobuf() {
        // Given
        var entries = LambdaMappingEntries()
        entries.mappingSlot(mappingSlot)
        entries.setEntries(makeEntries())

        // When
        let proto = entries.toProtobuf()

        // Then
        XCTAssertEqual(proto.mappingSlot, mappingSlot)
        XCTAssertEqual(proto.entries.count, makeEntries().count)
    }
}
