// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The details needed to create a hook on an entity.
///
/// Hooks are created by including `HookCreationDetails` in entity-creation or entity-update
/// transactions such as `AccountCreateTransaction`, `AccountUpdateTransaction`,
/// `ContractCreateTransaction`, or `ContractUpdateTransaction`.
///
/// Each hook is identified by an arbitrary 64-bit `hookId` that is unique within the owning
/// entity. The `hookId` need not be sequential; however, an entity may only have one hook with
/// a given ID at a time.
public struct HookCreationDetails {
    /// The extension point this hook implements.
    public var hookExtensionPoint: HookExtensionPoint

    /// The arbitrary 64-bit identifier to assign to this hook within the owning entity.
    public var hookId: Int64

    /// The EVM hook implementation, including the contract whose bytecode provides the hook
    /// logic and optional initial storage.
    public var evmHook: EvmHook?

    /// An optional key that can be used to remove or replace the hook, or to authorize
    /// `HookStoreTransaction`s that update the hook's storage.
    public var adminKey: Key?

    /// Create a new `HookCreationDetails`.
    ///
    /// - Parameters:
    ///   - hookExtensionPoint: The extension point for the hook.
    ///   - hookId: The ID to assign to the hook within the owning entity.
    ///   - evmHook: The EVM hook implementation.
    ///   - adminKey: An optional admin key for the hook.
    public init(
        hookExtensionPoint: HookExtensionPoint,
        hookId: Int64 = 0,
        evmHook: EvmHook? = nil,
        adminKey: Key? = nil
    ) {
        self.hookExtensionPoint = hookExtensionPoint
        self.hookId = hookId
        self.evmHook = evmHook
        self.adminKey = adminKey
    }

    /// Sets the extension point this hook implements.
    @discardableResult
    public mutating func hookExtensionPoint(_ hookExtensionPoint: HookExtensionPoint) -> Self {
        self.hookExtensionPoint = hookExtensionPoint
        return self
    }

    /// Sets the arbitrary 64-bit identifier to assign to this hook.
    @discardableResult
    public mutating func hookId(_ hookId: Int64) -> Self {
        self.hookId = hookId
        return self
    }

    /// Sets the EVM hook implementation.
    @discardableResult
    public mutating func evmHook(_ hook: EvmHook) -> Self {
        self.evmHook = hook
        return self
    }

    /// Sets the admin key for this hook.
    ///
    /// If set, this key can be used to remove or replace the hook, or to authorize
    /// `HookStoreTransaction`s that update the hook's storage.
    @discardableResult
    public mutating func adminKey(_ key: Key?) -> Self {
        self.adminKey = key
        return self
    }
}

extension HookCreationDetails: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_HookCreationDetails

    internal init(protobuf proto: Protobuf) throws {
        self.hookExtensionPoint = try HookExtensionPoint(protobuf: proto.extensionPoint)
        self.hookId = proto.hookID

        switch proto.hook {
        case .evmHook(let v):
            self.evmHook = try EvmHook(protobuf: v)
        default:
            self.evmHook = nil
        }

        self.adminKey = proto.hasAdminKey ? try Key(protobuf: proto.adminKey) : nil
    }

    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()
        proto.extensionPoint = hookExtensionPoint.toProtobuf()
        proto.hookID = hookId

        if let hook = evmHook {
            proto.hook = .evmHook(hook.toProtobuf())
        } else {
            proto.hook = nil
        }

        if let key = adminKey {
            proto.adminKey = key.toProtobuf()
        }

        return proto
    }
}
