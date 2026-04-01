// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

internal final class EvmHookUnitTests: XCTestCase {

    private func makeStorageSlot(key: Data, value: Data) -> EvmHookStorageSlot {
        var s = EvmHookStorageSlot()
        s.key(key)
        s.value(value)
        return s
    }

    private func makeEntryWithKey(_ key: Data, value: Data) -> EvmHookMappingEntry {
        var e = EvmHookMappingEntry()
        e.key(key)
        e.value(value)
        return e
    }

    private func makeEntryWithPreimage(_ preimage: Data, value: Data) -> EvmHookMappingEntry {
        var e = EvmHookMappingEntry()
        e.preimage(preimage)
        e.value(value)
        return e
    }

    private func makeMappingEntries(mappingSlot: Data, _ entries: [EvmHookMappingEntry]) -> EvmHookMappingEntries {
        var me = EvmHookMappingEntries()
        me.mappingSlot(mappingSlot)
        me.setEntries(entries)
        return me
    }

    private func makeStorageUpdateStorageSlot(_ slot: EvmHookStorageSlot) -> EvmHookStorageUpdate {
        var u = EvmHookStorageUpdate()
        u.setStorageSlot(slot)
        return u
    }

    private func makeStorageUpdateMappingEntries(_ entries: EvmHookMappingEntries) -> EvmHookStorageUpdate {
        var u = EvmHookStorageUpdate()
        u.setMappingEntries(entries)
        return u
    }

    private func makeUpdates() -> [EvmHookStorageUpdate] {
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

    internal func test_GetSetStorageUpdates() {
        var hook = EvmHook()
        let updates = makeUpdates()

        hook.setStorageUpdates(updates)

        XCTAssertEqual(hook.storageUpdates.count, updates.count)
    }

    internal func test_AddStorageUpdate() {
        var hook = EvmHook()
        let updates = makeUpdates()

        for u in updates {
            hook.addStorageUpdate(u)
        }

        XCTAssertEqual(hook.storageUpdates.count, updates.count)
    }

    internal func test_ClearStorageUpdates() {
        var hook = EvmHook()
        hook.setStorageUpdates(makeUpdates())

        hook.clearStorageUpdates()

        XCTAssertTrue(hook.storageUpdates.isEmpty)
    }

    internal func test_GetSetContractId() {
        let contractId = ContractId(shard: 1, realm: 2, num: 3)
        var hook = EvmHook()

        hook.contractId(contractId)

        XCTAssertEqual(hook.contractId, contractId)
    }

    internal func test_FromProtobuf() throws {
        var proto = Com_Hedera_Hapi_Node_Hooks_EvmHook()
        var spec = Com_Hedera_Hapi_Node_Hooks_EvmHookSpec()
        spec.bytecodeSource = .contractID(ContractId(shard: 1, realm: 2, num: 3).toProtobuf())
        proto.spec = spec
        proto.storageUpdates = makeUpdates().map { $0.toProtobuf() }

        let decoded = try EvmHook.fromProtobuf(proto)

        XCTAssertEqual(decoded.contractId, ContractId(shard: 1, realm: 2, num: 3))
        XCTAssertEqual(decoded.storageUpdates.count, proto.storageUpdates.count)
    }

    internal func test_ToProtobuf() {
        let contractId = ContractId(shard: 1, realm: 2, num: 3)
        var hook = EvmHook()
        hook.contractId(contractId)
        let updates = makeUpdates()
        hook.setStorageUpdates(updates)

        let proto = hook.toProtobuf()

        XCTAssertEqual(proto.storageUpdates.count, updates.count)
        guard case .contractID(let protoContractId)? = proto.spec.bytecodeSource else {
            XCTFail("Expected bytecodeSource to be .contractID")
            return
        }
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoContractId.contractNum), contractId.num)
    }
}
