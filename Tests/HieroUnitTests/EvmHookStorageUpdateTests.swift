// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

internal final class EvmHookStorageUpdateUnitTests: XCTestCase {

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

    private func makeEntries() -> EvmHookMappingEntries {
        var le = EvmHookMappingEntries()
        le.setEntries([makeEntry1(), makeEntry2(), makeEntry3()])
        le.mappingSlot(mappingSlot)
        return le
    }

    private func makeStorageSlot() -> EvmHookStorageSlot {
        var s = EvmHookStorageSlot()
        s.key(key1)
        s.value(value1)
        return s
    }

    internal func test_GetSetStorageSlot() {
        var update = EvmHookStorageUpdate()

        update.setStorageSlot(makeStorageSlot())

        XCTAssertNotNil(update.storageSlot)
        XCTAssertEqual(update.storageSlot?.key, key1)
        XCTAssertEqual(update.storageSlot?.value, value1)
    }

    internal func test_GetSetMappingEntries() {
        var update = EvmHookStorageUpdate()
        let entries = makeEntries()

        update.setMappingEntries(entries)

        XCTAssertNotNil(update.mappingEntries)
        XCTAssertEqual(update.mappingEntries?.entries.count, entries.entries.count)
    }

    internal func test_SetStorageSlotResetsMappingEntries() {
        var update = EvmHookStorageUpdate()

        update.setMappingEntries(makeEntries())
        update.setStorageSlot(makeStorageSlot())

        XCTAssertNil(update.mappingEntries)
    }

    internal func test_SetMappingEntriesResetsStorageSlot() {
        var update = EvmHookStorageUpdate()

        update.setStorageSlot(makeStorageSlot())
        update.setMappingEntries(makeEntries())

        XCTAssertNil(update.storageSlot)
    }

    internal func test_FromProtobuf() throws {
        var protoSlot = Com_Hedera_Hapi_Node_Hooks_EvmHookStorageUpdate()
        protoSlot.storageSlot = makeStorageSlot().toProtobuf()

        var protoEntries = Com_Hedera_Hapi_Node_Hooks_EvmHookStorageUpdate()
        protoEntries.mappingEntries = makeEntries().toProtobuf()

        let decodedSlot = try EvmHookStorageUpdate.fromProtobuf(protoSlot)
        let decodedEntries = try EvmHookStorageUpdate.fromProtobuf(protoEntries)

        XCTAssertNotNil(decodedSlot.storageSlot)
        XCTAssertEqual(decodedSlot.storageSlot?.key, key1)
        XCTAssertEqual(decodedSlot.storageSlot?.value, value1)

        XCTAssertNotNil(decodedEntries.mappingEntries)
        XCTAssertEqual(decodedEntries.mappingEntries?.entries.count, 3)
    }

    internal func test_ToProtobuf() {
        var updateSlot = EvmHookStorageUpdate()
        var updateEntries = EvmHookStorageUpdate()

        updateSlot.setStorageSlot(makeStorageSlot())
        updateEntries.setMappingEntries(makeEntries())

        let protoSlot = updateSlot.toProtobuf()
        let protoEntries = updateEntries.toProtobuf()

        XCTAssertEqual(protoSlot.storageSlot.key, key1)
        XCTAssertEqual(protoSlot.storageSlot.value, value1)

        XCTAssertEqual(protoEntries.mappingEntries.mappingSlot, mappingSlot)
        XCTAssertEqual(protoEntries.mappingEntries.entries.count, 3)
    }
}
