// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

final class LambdaEvmHookUnitTests: XCTestCase {

    private func makeStorageSlot(key: Data, value: Data) -> LambdaStorageSlot {
        var s = LambdaStorageSlot()
        s.key(key)
        s.value(value)
        return s
    }

    private func makeEntryWithKey(_ key: Data, value: Data) -> LambdaMappingEntry {
        var e = LambdaMappingEntry()
        e.key(key)
        e.value(value)
        return e
    }

    private func makeEntryWithPreimage(_ preimage: Data, value: Data) -> LambdaMappingEntry {
        var e = LambdaMappingEntry()
        e.preimage(preimage)
        e.value(value)
        return e
    }

    private func makeMappingEntries(mappingSlot: Data, _ entries: [LambdaMappingEntry]) -> LambdaMappingEntries {
        var me = LambdaMappingEntries()
        me.mappingSlot(mappingSlot)
        me.setEntries(entries)
        return me
    }

    private func makeStorageUpdateStorageSlot(_ slot: LambdaStorageSlot) -> LambdaStorageUpdate {
        var u = LambdaStorageUpdate()
        u.setStorageSlot(slot)
        return u
    }

    private func makeStorageUpdateMappingEntries(_ entries: LambdaMappingEntries) -> LambdaStorageUpdate {
        var u = LambdaStorageUpdate()
        u.setMappingEntries(entries)
        return u
    }

    private func makeUpdates() -> [LambdaStorageUpdate] {
        // test bytes
        let key1 = Data([0x01, 0x23, 0x45])
        let key2 = Data([0x67, 0x89, 0xAB])
        let preimage = Data([0xCD, 0xEF, 0x02])

        let value1 = Data([0x04, 0x06, 0x08])
        let value2 = Data([0x0A, 0x0C, 0x0E])
        let value3 = Data([0x11, 0x13, 0x15])

        let mappingSlot = Data([0x17, 0x19, 0x1B])

        let slot = makeStorageSlot(key: key1, value: value1)
        let update1 = makeStorageUpdateStorageSlot(slot)

        let e1 = makeEntryWithKey(key2, value: value2)
        let e2 = makeEntryWithPreimage(preimage, value: value3)
        let me = makeMappingEntries(mappingSlot: mappingSlot, [e1, e2])
        let update2 = makeStorageUpdateMappingEntries(me)

        return [update1, update2]
    }

    func test_GetSetStorageUpdates() {
        // Given
        var hook = LambdaEvmHook()
        let updates = makeUpdates()

        // When
        hook.setStorageUpdates(updates)

        // Then
        XCTAssertEqual(hook.storageUpdates.count, updates.count)
    }

    func test_AddStorageUpdate() {
        // Given
        var hook = LambdaEvmHook()
        let updates = makeUpdates()

        // When
        for u in updates {
            hook.addStorageUpdate(u)
        }

        // Then
        XCTAssertEqual(hook.storageUpdates.count, updates.count)
    }

    func test_ClearStorageUpdates() {
        // Given
        var hook = LambdaEvmHook()
        hook.setStorageUpdates(makeUpdates())

        // When
        hook.clearStorageUpdates()

        // Then
        XCTAssertTrue(hook.storageUpdates.isEmpty)
    }

    func test_FromProtobuf() throws {
        // Given
        var proto = Com_Hedera_Hapi_Node_Hooks_LambdaEvmHook()
        proto.storageUpdates = makeUpdates().map { $0.toProtobuf() }

        // When
        let decoded = try LambdaEvmHook.fromProtobuf(proto)

        // Then
        XCTAssertEqual(decoded.storageUpdates.count, proto.storageUpdates.count)
    }

    func test_ToProtobuf() {
        // Given
        var hook = LambdaEvmHook()
        let updates = makeUpdates()
        hook.setStorageUpdates(updates)

        // When
        let proto = hook.toProtobuf()

        // Then
        XCTAssertEqual(proto.storageUpdates.count, updates.count)
    }
}
