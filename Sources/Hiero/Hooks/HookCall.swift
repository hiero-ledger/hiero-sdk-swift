// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

public struct HookCall {
    public var fullHookId: HookId?
    public var hookId: Int64?
    public var evmHookCall: EvmHookCall?

    public init() {}

    public init(fullHookId: HookId? = nil, evmHookCall: EvmHookCall? = nil) {
        self.fullHookId = fullHookId
        self.hookId = nil
        self.evmHookCall = evmHookCall
    }

    public init(hookId: Int64? = nil, evmHookCall: EvmHookCall? = nil) {
        self.fullHookId = nil
        self.hookId = hookId
        self.evmHookCall = evmHookCall
    }

    @discardableResult
    public mutating func fullHookId(_ hookId: HookId) -> Self {
        self.fullHookId = hookId
        self.hookId = nil
        return self
    }

    @discardableResult
    public mutating func hookId(_ hookId: Int64) -> Self {
        self.hookId = hookId
        self.fullHookId = nil
        return self
    }

    @discardableResult
    public mutating func evmHookCall(_ evmHookCall: EvmHookCall) -> Self {
        self.evmHookCall = evmHookCall
        return self
    }
}

extension HookCall: TryProtobufCodable {
    internal typealias Protobuf = Proto_HookCall

    internal init(protobuf proto: Protobuf) throws {
        // Map the `oneof id`
        switch proto.id {
        case .fullHookID(let v):
            self.fullHookId = try HookId(protobuf: v)
            self.hookId = nil
        case .hookID(let v):
            self.fullHookId = nil
            self.hookId = v
        case nil:
            self.fullHookId = nil
            self.hookId = nil
        }

        // Map the `oneof callSpec`
        switch proto.callSpec {
        case .evmHookCall(let v):
            self.evmHookCall = try EvmHookCall(protobuf: v)
        case nil:
            self.evmHookCall = nil
        }
    }

    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()

        // Set the `oneof id`
        if let full = fullHookId {
            proto.id = .fullHookID(full.toProtobuf())
        } else if let id = hookId {
            proto.id = .hookID(id)
        } else {
            proto.id = nil
        }

        // Set the `oneof callSpec`
        if let evm = evmHookCall {
            proto.callSpec = .evmHookCall(evm.toProtobuf())
        } else {
            proto.callSpec = nil
        }

        return proto
    }
}
