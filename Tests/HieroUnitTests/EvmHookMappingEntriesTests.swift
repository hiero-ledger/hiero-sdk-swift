// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

internal final class EvmHookMappingEntriesUnitTests: XCTestCase {

    private let mappingSlot = Data([0x17, 0x19, 0x1B])

    private let key1 = Data([0x01, 0x23, 0x45])
    private let key3 = Data([0x67, 0x89, 0xAB])
    private let preimage2 = Data([0xCD, 0xEF, 0x02])

    private let value1 = Data([0x04, 0x06, 0x08])
    private let value2 = Data([0x0A, 0x0C, 0x0E])
    private let value3 = Data([0x11, 0x13, 0x15])

    private func makeEntry1() -> EvmHookMappingEntry {
        var e = EvmHookMappingEntry()
        e.key(key1)
        e.value(value1)
        return e
    }

    private func makeEntry2() -> EvmHookMappingEntry {
        var e = EvmHookMappingEntry()
        e.preimage(preimage2)
        e.value(value2)
        return e
    }

    private func makeEntry3() -> EvmHookMappingEntry {
        var e = EvmHookMappingEntry()
        e.key(key3)
        e.value(value3)
        return e
    }

    private func makeEntries() -> [EvmHookMappingEntry] {
        [makeEntry1(), makeEntry2(), makeEntry3()]
    }

    internal func test_GetSetMappingSlot() {
        var entries = EvmHookMappingEntries()

        entries.mappingSlot(mappingSlot)

        XCTAssertEqual(entries.mappingSlot, mappingSlot)
    }

    internal func test_GetSetEntries() {
        var entries = EvmHookMappingEntries()

        entries.setEntries(makeEntries())

        XCTAssertEqual(entries.entries.count, makeEntries().count)
    }

    internal func test_AddEntry() {
        var entries = EvmHookMappingEntries()
        let e1 = makeEntry1()

        entries.addEntry(e1)

        XCTAssertEqual(entries.entries.count, 1)
        XCTAssertNotNil(entries.entries[0].key)
        XCTAssertEqual(entries.entries[0].key, key1)
        XCTAssertEqual(entries.entries[0].value, value1)
    }

    internal func test_ClearEntries() {
        var entries = EvmHookMappingEntries()
        entries.setEntries(makeEntries())

        entries.clearEntries()

        XCTAssertTrue(entries.entries.isEmpty)
    }

    internal func test_FromProtobuf() throws {
        var proto = Com_Hedera_Hapi_Node_Hooks_EvmHookMappingEntries()
        proto.mappingSlot = mappingSlot
        proto.entries = makeEntries().map { $0.toProtobuf() }

        let decoded = try EvmHookMappingEntries.fromProtobuf(proto)

        XCTAssertEqual(decoded.mappingSlot, mappingSlot)
        XCTAssertEqual(decoded.entries.count, makeEntries().count)
    }

    internal func test_ToProtobuf() {
        var entries = EvmHookMappingEntries()
        entries.mappingSlot(mappingSlot)
        entries.setEntries(makeEntries())

        let proto = entries.toProtobuf()

        XCTAssertEqual(proto.mappingSlot, mappingSlot)
        XCTAssertEqual(proto.entries.count, makeEntries().count)
    }
}
