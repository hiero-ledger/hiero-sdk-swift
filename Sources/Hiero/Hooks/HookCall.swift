// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies a call to a hook from within a transaction where the hook owner is implied
/// by the point of use.
///
/// For example, if the hook is an account allowance hook, then it is clear from the balance
/// adjustment being attempted which account must own the referenced hook.
public struct HookCall {
    /// The ID of the hook to call, relative to the owning entity.
    public var hookId: Int64?

    /// The specification of how to call the EVM hook, including call data and gas limit.
    public var evmHookCall: EvmHookCall?

    /// Create a new `HookCall`.
    ///
    /// - Parameters:
    ///   - hookId: The ID of the hook to call.
    ///   - evmHookCall: The EVM-specific call details.
    public init(hookId: Int64? = nil, evmHookCall: EvmHookCall? = nil) {
        self.hookId = hookId
        self.evmHookCall = evmHookCall
    }

    /// Sets the ID of the hook to call.
    @discardableResult
    public mutating func hookId(_ hookId: Int64) -> Self {
        self.hookId = hookId
        return self
    }

    /// Sets the EVM-specific call details.
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
