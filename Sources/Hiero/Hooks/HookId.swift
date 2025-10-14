// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// An ID for a hook.
public struct HookId {
    /// The hook's owning entity ID.
    public var entityId: HookEntityId

    /// The ID for the hook.
    public var hookId: Int64

    public init(entityId: HookEntityId = HookEntityId(), hookId: Int64 = 0) {
        self.entityId = entityId
        self.hookId = hookId
    }

    /// Set the ID of the owning entity.
    @discardableResult
    public mutating func entityId(_ entityId: HookEntityId) -> Self {
        self.entityId = entityId
        return self
    }

    /// Set the ID of the hook.
    @discardableResult
    public mutating func hookId(_ hookId: Int64) -> Self {
        self.hookId = hookId
        return self
    }
}

extension HookId: TryProtobufCodable {
    internal typealias Protobuf = Proto_HookId

    /// Construct a `HookId` from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        self.entityId = try HookEntityId(protobuf: proto.entityID)
        self.hookId = proto.hookID
    }

    /// Convert this `HookId` to protobuf.
    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.entityID = entityId.toProtobuf()
            proto.hookID = hookId
        }
    }
}
