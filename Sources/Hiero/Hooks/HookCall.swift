// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

public struct HookCall {
    public var hookId: Int64?
    public var evmHookCall: EvmHookCall?

    public init() {}

    public init(hookId: Int64? = nil, evmHookCall: EvmHookCall? = nil) {
        self.hookId = hookId
        self.evmHookCall = evmHookCall
    }

    @discardableResult
    public mutating func hookId(_ hookId: Int64) -> Self {
        self.hookId = hookId
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
        switch proto.id {
        case .hookID(let v):
            self.hookId = v
        case nil:
            self.hookId = nil
        }

        switch proto.callSpec {
        case .evmHookCall(let v):
            self.evmHookCall = try EvmHookCall(protobuf: v)
        case nil:
            self.evmHookCall = nil
        }
    }

    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()

        if let id = hookId {
            proto.id = .hookID(id)
        } else {
            proto.id = nil
        }

        if let evm = evmHookCall {
            proto.callSpec = .evmHookCall(evm.toProtobuf())
        } else {
            proto.callSpec = nil
        }

        return proto
    }
}

extension HookCall: ValidateChecksums {
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try evmHookCall?.validateChecksums(on: ledgerId)
    }
}
