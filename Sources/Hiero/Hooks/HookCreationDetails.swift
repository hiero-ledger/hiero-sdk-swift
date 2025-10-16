// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

public struct HookCreationDetails {
    public var hookExtensionPoint: HookExtensionPoint
    public var hookId: Int64
    public var lambdaEvmHook: LambdaEvmHook?
    public var adminKey: Key?

    public init(
        hookExtensionPoint: HookExtensionPoint,
        hookId: Int64 = 0,
        lambdaEvmHook: LambdaEvmHook? = nil,
        adminKey: Key? = nil
    ) {
        self.hookExtensionPoint = hookExtensionPoint
        self.hookId = hookId
        self.lambdaEvmHook = lambdaEvmHook
        self.adminKey = adminKey
    }

    @discardableResult
    public mutating func hookExtensionPoint(_ hookExtensionPoint: HookExtensionPoint) -> Self {
        self.hookExtensionPoint = hookExtensionPoint
        return self
    }

    @discardableResult
    public mutating func hookId(_ hookId: Int64) -> Self {
        self.hookId = hookId
        return self
    }

    @discardableResult
    public mutating func lambdaEvmHook(_ hook: LambdaEvmHook) -> Self {
        self.lambdaEvmHook = hook
        return self
    }

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

        // Only accept lambda; anything else => nil
        switch proto.hook {
        case .lambdaEvmHook(let v):
            self.lambdaEvmHook = try LambdaEvmHook(protobuf: v)
        default:
            self.lambdaEvmHook = nil
        }

        self.adminKey = proto.hasAdminKey ? try Key(protobuf: proto.adminKey) : nil
    }

    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()
        proto.extensionPoint = hookExtensionPoint.toProtobuf()
        proto.hookID = hookId

        // Only encode lambda; otherwise leave the oneof unset (nil)
        if let lambda = lambdaEvmHook {
            proto.hook = .lambdaEvmHook(lambda.toProtobuf())
        } else {
            proto.hook = nil
        }

        if let key = adminKey {
            proto.adminKey = key.toProtobuf()
        }  // else: leave unset

        return proto
    }
}
