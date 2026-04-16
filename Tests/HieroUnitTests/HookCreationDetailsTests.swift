// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

internal final class HookCreationDetailsUnitTests: XCTestCase {

    private func makeStorageSlot(_ key: Data, _ value: Data) -> EvmHookStorageSlot {
        var s = EvmHookStorageSlot()
        s.key(key)
        s.value(value)
        return s
    }

    private func makeEntryWithKey(_ key: Data, _ value: Data) -> EvmHookMappingEntry {
        var e = EvmHookMappingEntry()
        e.key(key)
        e.value(value)
        return e
    }

    private func makeEntryWithPreimage(_ preimage: Data, _ value: Data) -> EvmHookMappingEntry {
        var e = EvmHookMappingEntry()
        e.preimage(preimage)
        e.value(value)
        return e
    }

    private func makeMappingEntries(_ mappingSlot: Data, _ entries: [EvmHookMappingEntry]) -> EvmHookMappingEntries {
        var me = EvmHookMappingEntries()
        me.setEntries(entries)
        me.mappingSlot(mappingSlot)
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

    private func makeEvmHook() -> EvmHook {
        let key1 = Data([0x01, 0x23, 0x45])
        let key2 = Data([0x67, 0x89, 0xAB])
        let preimage = Data([0xCD, 0xEF, 0x02])

        let value1 = Data([0x04, 0x06, 0x08])
        let value2 = Data([0x0A, 0x0C, 0x0E])
        let value3 = Data([0x11, 0x13, 0x15])

        let mappingSlot = Data([0x17, 0x19, 0x1B])

        let slot = makeStorageSlot(key1, value1)
        let update1 = makeStorageUpdateStorageSlot(slot)

        let e1 = makeEntryWithKey(key2, value2)
        let e2 = makeEntryWithPreimage(preimage, value3)
        let me = makeMappingEntries(mappingSlot, [e1, e2])
        let update2 = makeStorageUpdateMappingEntries(me)

        var hook = EvmHook()
        hook.addStorageUpdate(update1)
        hook.addStorageUpdate(update2)
        return hook
    }

    private func makeAdminKey() throws -> Key {
        let priv = PrivateKey.generateEcdsa()
        return .single(priv.publicKey)
    }

    internal func test_GetSetHookId() throws {
        var details = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)

        details.hookId(1)

        XCTAssertEqual(details.hookId, 1)
    }

    internal func test_GetSetEvmHook() {
        var details = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        let hook = makeEvmHook()

        details.evmHook(hook)

        XCTAssertNotNil(details.evmHook)
        XCTAssertEqual(details.evmHook?.storageUpdates.count, hook.storageUpdates.count)
    }

    internal func test_GetSetAdminKey() throws {
        var details = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        let key = try makeAdminKey()

        details.adminKey(key)

        XCTAssertNotNil(details.adminKey)
        XCTAssertEqual(details.adminKey?.toBytes(), key.toBytes())
    }

    internal func test_FromProtobuf() throws {
        var proto = Com_Hedera_Hapi_Node_Hooks_HookCreationDetails()
        proto.extensionPoint = HookExtensionPoint.accountAllowanceHook.toProtobuf()
        proto.hookID = 1
        proto.hook = .evmHook(makeEvmHook().toProtobuf())

        let key = try makeAdminKey()
        proto.adminKey = key.toProtobuf()

        let decoded = try HookCreationDetails.fromProtobuf(proto)

        XCTAssertEqual(decoded.hookExtensionPoint, .accountAllowanceHook)
        XCTAssertEqual(decoded.hookId, 1)
        XCTAssertNotNil(decoded.evmHook)
        XCTAssertNotNil(decoded.adminKey)
    }

    internal func test_ToProtobuf() throws {
        var details = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        details.hookId(1)
        details.evmHook(makeEvmHook())

        let key = try makeAdminKey()
        details.adminKey(key)

        let proto = details.toProtobuf()

        XCTAssertEqual(proto.extensionPoint, HookExtensionPoint.accountAllowanceHook.toProtobuf())
        XCTAssertEqual(proto.hookID, 1)
        XCTAssertEqual(proto.hook, .evmHook(proto.evmHook))
        XCTAssertTrue(proto.hasAdminKey)
    }
}
