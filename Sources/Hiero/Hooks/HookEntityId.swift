// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs

public final class HookEntityId {
    /// ID of the account that owns a hook.
    public var accountId: AccountId?

    public init(_ accountId: AccountId) {
        self.accountId = accountId
    }

    /// Sets the ID of the account that owns a hook.
    @discardableResult
    public func accountId(_ accountId: AccountId) -> Self {
        self.accountId = accountId
        return self
    }
}

extension HookEntityId: TryProtobufCodable {
    internal typealias Protobuf = Proto_HookEntityId

    /// Creates a hook entity ID from a hook entity ID protobuf.
    ///
    /// - Parameters:
    ///   - proto: the hook entity ID protobuf.
    internal convenience init(protobuf proto: Protobuf) throws {
        let id = try AccountId.fromProtobuf(proto.accountID)
        self.init(id)
    }

    /// Converts this hook entity ID to a protobuf.
    internal func toProtobuf() -> Protobuf {
        .with { proto in
            if let id = accountId {
                proto.accountID = id.toProtobuf()
            }
        }
    }
}
