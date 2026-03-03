// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies a call to an account allowance hook for a fungible token transfer (including HBAR).
///
/// Used with `TransferTransaction.addHbarTransferWithHook` and
/// `AbstractTokenTransferTransaction.addTokenTransferWithHook` to reference an allowance hook
/// on the sender or receiver account. The `hookType` determines whether the hook is called
/// before the transfer only, or both before and after.
public struct FungibleHookCall {
    /// The underlying hook call details (hook ID and EVM call parameters).
    public var hookCall: HookCall

    /// The type of fungible hook invocation (pre-only or pre-and-post, for sender or receiver).
    public var hookType: FungibleHookType

    /// Create a new `FungibleHookCall`.
    ///
    /// - Parameters:
    ///   - hookCall: The underlying hook call details.
    ///   - hookType: The type of fungible hook invocation.
    public init(hookCall: HookCall = HookCall(), hookType: FungibleHookType = .uninitialized) {
        self.hookCall = hookCall
        self.hookType = hookType
    }

    /// Sets the underlying hook call details.
    @discardableResult
    public mutating func hookCall(_ hookCall: HookCall) -> Self {
        self.hookCall = hookCall
        return self
    }

    /// Sets the type of fungible hook invocation.
    @discardableResult
    public mutating func hookType(_ hookType: FungibleHookType) -> Self {
        self.hookType = hookType
        return self
    }

    /// Sets the ID of the hook to call on the underlying `HookCall`.
    @discardableResult
    public mutating func hookId(_ hookId: Int64) -> Self {
        self.hookCall.hookId = hookId
        return self
    }

    /// Sets the EVM-specific call details on the underlying `HookCall`.
    @discardableResult
    public mutating func evmHookCall(_ evmHookCall: EvmHookCall) -> Self {
        self.hookCall.evmHookCall = evmHookCall
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
