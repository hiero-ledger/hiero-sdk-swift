// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

final class LambdaStorageUpdateUnitTests: XCTestCase {

    // Fixture-equivalent constants
    private let mappingSlot = Data([0x17, 0x19, 0x1B])

    private let key1 = Data([0x01, 0x23, 0x45])
    private let key3 = Data([0x67, 0x89, 0xAB])

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

    private func makeEntries() -> LambdaMappingEntries {
        var le = LambdaMappingEntries()
        le.setEntries([makeEntry1(), makeEntry2(), makeEntry3()])
        le.mappingSlot(mappingSlot)
        return le
    }

    private func makeStorageSlot() -> LambdaStorageSlot {
        var s = LambdaStorageSlot()
        s.key(key1)
        s.value(value1)
        return s
    }

    func test_GetSetStorageSlot() {
        // Given
        var update = LambdaStorageUpdate()

        // When
        update.setStorageSlot(makeStorageSlot())

        // Then
        XCTAssertNotNil(update.storageSlot)
        XCTAssertEqual(update.storageSlot?.key, key1)
        XCTAssertEqual(update.storageSlot?.value, value1)
    }

    func test_GetSetMappingEntries() {
        // Given
        var update = LambdaStorageUpdate()
        let entries = makeEntries()

        // When
        update.setMappingEntries(entries)

        // Then
        XCTAssertNotNil(update.mappingEntries)
        XCTAssertEqual(update.mappingEntries?.entries.count, entries.entries.count)
    }

    func test_SetStorageSlotResetsMappingEntries() {
        // Given
        var update = LambdaStorageUpdate()

        // When
        update.setMappingEntries(makeEntries())
        update.setStorageSlot(makeStorageSlot())

        // Then
        XCTAssertNil(update.mappingEntries)
    }

    func test_SetMappingEntriesResetsStorageSlot() {
        // Given
        var update = LambdaStorageUpdate()

        // When
        update.setStorageSlot(makeStorageSlot())
        update.setMappingEntries(makeEntries())

        // Then
        XCTAssertNil(update.storageSlot)
    }

    func test_FromProtobuf() throws {
        // Given
        var protoSlot = Com_Hedera_Hapi_Node_Hooks_LambdaStorageUpdate()
        protoSlot.storageSlot = makeStorageSlot().toProtobuf()

        var protoEntries = Com_Hedera_Hapi_Node_Hooks_LambdaStorageUpdate()
        protoEntries.mappingEntries = makeEntries().toProtobuf()

        // When
        let decodedSlot = try LambdaStorageUpdate.fromProtobuf(protoSlot)
        let decodedEntries = try LambdaStorageUpdate.fromProtobuf(protoEntries)

        // Then
        XCTAssertNotNil(decodedSlot.storageSlot)
        XCTAssertEqual(decodedSlot.storageSlot?.key, key1)
        XCTAssertEqual(decodedSlot.storageSlot?.value, value1)

        XCTAssertNotNil(decodedEntries.mappingEntries)
        XCTAssertEqual(decodedEntries.mappingEntries?.entries.count, 3)
    }

    func test_ToProtobuf() {
        // Given
        var updateSlot = LambdaStorageUpdate()
        var updateEntries = LambdaStorageUpdate()

        updateSlot.setStorageSlot(makeStorageSlot())
        updateEntries.setMappingEntries(makeEntries())

        // When
        let protoSlot = updateSlot.toProtobuf()
        let protoEntries = updateEntries.toProtobuf()

        // Then
        // storageSlot path
        XCTAssertEqual(protoSlot.storageSlot.key, key1)
        XCTAssertEqual(protoSlot.storageSlot.value, value1)

        // mappingEntries path
        XCTAssertEqual(protoEntries.mappingEntries.mappingSlot, mappingSlot)
        XCTAssertEqual(protoEntries.mappingEntries.entries.count, 3)
    }
}
