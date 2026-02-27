// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The fully-qualified identifier for a created hook.
///
/// A hook's full ID is a composite of its owning entity's ID and an arbitrary 64-bit hook ID.
/// The hook ID need not be sequential relative to other hooks owned by the entity, but an
/// entity may only have one hook with a given ID at a time.
public struct HookId {
    /// The ID of the entity that owns this hook.
    public var entityId: HookEntityId

    /// The arbitrary 64-bit identifier for this hook within its owning entity.
    public var hookId: Int64

    /// Create a new `HookId`.
    ///
    /// - Parameters:
    ///   - entityId: The ID of the owning entity.
    ///   - hookId: The hook's 64-bit identifier.
    public init(entityId: HookEntityId = HookEntityId(), hookId: Int64 = 0) {
        self.entityId = entityId
        self.hookId = hookId
    }

    /// Sets the ID of the owning entity.
    @discardableResult
    public mutating func entityId(_ entityId: HookEntityId) -> Self {
        self.entityId = entityId
        return self
    }

    /// Sets the hook's 64-bit identifier.
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

extension HookId: ValidateChecksums {
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try entityId.validateChecksums(on: ledgerId)
    }
}
