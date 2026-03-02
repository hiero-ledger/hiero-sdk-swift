// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies a call to an account allowance hook for an NFT transfer.
///
/// Used with `AbstractTokenTransferTransaction.addNftTransferWithHook` to reference an
/// allowance hook on either the sender or receiver account of an NFT transfer. Unlike
/// fungible hooks, NFT transfers support both a sender and a receiver hook on the same
/// `NftTransfer`, since the receiver hook can satisfy `receiver_sig_required=true`.
public struct NftHookCall {
    /// The underlying hook call details (hook ID and EVM call parameters).
    public var hookCall: HookCall

    /// The type of NFT hook invocation (pre-only or pre-and-post).
    public var hookType: NftHookType

    /// Create a new `NftHookCall`.
    ///
    /// - Parameters:
    ///   - hookCall: The underlying hook call details.
    ///   - hookType: The type of NFT hook invocation.
    public init(hookCall: HookCall = HookCall(), hookType: NftHookType = .uninitialized) {
        self.hookCall = hookCall
        self.hookType = hookType
    }

    /// Sets the underlying hook call details.
    @discardableResult
    public mutating func hookCall(_ hookCall: HookCall) -> Self {
        self.hookCall = hookCall
        return self
    }

    /// Sets the type of NFT hook invocation.
    @discardableResult
    public mutating func hookType(_ hookType: NftHookType) -> Self {
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

extension NftHookCall: TryProtobufCodable {
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

extension NftHookCall: ValidateChecksums {
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try hookCall.validateChecksums(on: ledgerId)
    }
}
