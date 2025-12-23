// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

final class HookCreationDetailsUnitTests: XCTestCase {

    private func makeStorageSlot(_ key: Data, _ value: Data) -> LambdaStorageSlot {
        var s = LambdaStorageSlot()
        s.key(key)
        s.value(value)
        return s
    }

    private func makeEntryWithKey(_ key: Data, _ value: Data) -> LambdaMappingEntry {
        var e = LambdaMappingEntry()
        e.key(key)
        e.value(value)
        return e
    }

    private func makeEntryWithPreimage(_ preimage: Data, _ value: Data) -> LambdaMappingEntry {
        var e = LambdaMappingEntry()
        e.preimage(preimage)
        e.value(value)
        return e
    }

    private func makeMappingEntries(_ mappingSlot: Data, _ entries: [LambdaMappingEntry]) -> LambdaMappingEntries {
        var me = LambdaMappingEntries()
        me.setEntries(entries)
        me.mappingSlot(mappingSlot)
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

    private func makeLambdaEvmHook() -> LambdaEvmHook {
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

        var hook = LambdaEvmHook()
        hook.addStorageUpdate(update1)
        hook.addStorageUpdate(update2)
        return hook
    }

    private func makeAdminKey() throws -> Key {
        let priv = PrivateKey.generateEcdsa()
        return .single(priv.publicKey)
    }

    func test_GetSetHookId() throws {
        // Given
        var details = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)

        // When
        details.hookId(1)

        // Then
        XCTAssertEqual(details.hookId, 1)
    }

    func test_GetSetLambdaEvmHook() {
        // Given
        var details = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        let lambda = makeLambdaEvmHook()

        // When
        details.lambdaEvmHook(lambda)

        // Then
        XCTAssertNotNil(details.lambdaEvmHook)
        XCTAssertEqual(details.lambdaEvmHook?.storageUpdates.count, lambda.storageUpdates.count)
    }

    func test_GetSetAdminKey() throws {
        // Given
        var details = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        let key = try makeAdminKey()

        // When
        details.adminKey(key)

        // Then
        // Round-trip bytes check if your Key exposes them; otherwise just assert non-nil.
        XCTAssertNotNil(details.adminKey)
        XCTAssertEqual(details.adminKey?.toBytes(), key.toBytes())
    }

    func test_FromProtobuf() throws {
        // Given
        var proto = Com_Hedera_Hapi_Node_Hooks_HookCreationDetails()
        proto.extensionPoint = HookExtensionPoint.accountAllowanceHook.toProtobuf()
        proto.hookID = 1
        proto.lambdaEvmHook = makeLambdaEvmHook().toProtobuf()

        let key = try makeAdminKey()
        proto.adminKey = key.toProtobuf()

        // When
        let decoded = try HookCreationDetails.fromProtobuf(proto)

        // Then
        XCTAssertEqual(decoded.hookExtensionPoint, .accountAllowanceHook)
        XCTAssertEqual(decoded.hookId, 1)
        XCTAssertNotNil(decoded.lambdaEvmHook)
        XCTAssertNotNil(decoded.adminKey)
    }

    func test_ToProtobuf() throws {
        // Given
        var details = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        details.hookId(1)
        details.lambdaEvmHook(makeLambdaEvmHook())

        let key = try makeAdminKey()
        details.adminKey(key)

        // When
        let proto = details.toProtobuf()

        // Then
        XCTAssertEqual(proto.extensionPoint, HookExtensionPoint.accountAllowanceHook.toProtobuf())
        XCTAssertEqual(proto.hookID, 1)
        XCTAssertEqual(proto.hook, .lambdaEvmHook(proto.lambdaEvmHook))
        XCTAssertTrue(proto.hasAdminKey)
    }
}
