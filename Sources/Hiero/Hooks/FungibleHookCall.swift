// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies a call to a hook from within a transaction that interacts with fungible tokens (HBAR included).
public struct FungibleHookCall {
    /// The underlying hook call.
    public var hookCall: HookCall

    /// The type of the fungible hook to call.
    public var hookType: FungibleHookType

    public init(hookCall: HookCall = HookCall(), hookType: FungibleHookType = .uninitialized) {
        self.hookCall = hookCall
        self.hookType = hookType
    }

    /// Set the underlying hook call.
    @discardableResult
    public mutating func hookCall(_ hookCall: HookCall) -> Self {
        self.hookCall = hookCall
        return self
    }

    /// Set the type of the fungible hook to call.
    @discardableResult
    public mutating func hookType(_ hookType: FungibleHookType) -> Self {
        self.hookType = hookType
        return self
    }

    /// Set the full hook ID.
    @discardableResult
    public mutating func fullHookId(_ hookId: HookId) -> Self {
        self.hookCall.fullHookId(hookId)
        return self
    }

    /// Set the hook ID.
    @discardableResult
    public mutating func hookId(_ hookId: Int64) -> Self {
        self.hookCall.hookId(hookId)
        return self
    }

    /// Set the EVM hook call.
    @discardableResult
    public mutating func evmHookCall(_ evmHookCall: EvmHookCall) -> Self {
        self.hookCall.evmHookCall(evmHookCall)
        return self
    }
}

extension FungibleHookCall: TryProtobufCodable {
    internal typealias Protobuf = Proto_HookCall

    /// Construct from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        self.hookCall = try HookCall(protobuf: proto)
        // Note: The hook type is not stored in the protobuf, so we default to uninitialized
        // The caller should set the appropriate hook type based on context
        self.hookType = .uninitialized
    }

    /// Convert to protobuf.
    internal func toProtobuf() -> Protobuf {
        return hookCall.toProtobuf()
    }
}

extension FungibleHookCall: ValidateChecksums {
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try hookCall.validateChecksums(on: ledgerId)
    }
}
