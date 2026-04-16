// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies the details of a call to an EVM hook.
///
/// When a transaction references a hook, the `EvmHookCall` provides the extra call data
/// and gas limit for that specific hook invocation. The payer of the triggering transaction
/// pays for the upfront gas cost, and will never be charged more gas than the `gasLimit`
/// specified here.
public struct EvmHookCall {
    /// Extra call data to pass to the hook via the `IHieroHook.HookContext.data` field.
    public var data: Data

    /// The maximum amount of gas to use for this hook invocation.
    ///
    /// The payer will never be charged for more gas than this limit.
    public var gasLimit: UInt64

    /// Create a new `EvmHookCall`.
    ///
    /// - Parameters:
    ///   - data: Extra call data to pass to the hook.
    ///   - gasLimit: The gas limit for the hook invocation.
    public init(data: Data = Data(), gasLimit: UInt64 = 0) {
        self.data = data
        self.gasLimit = gasLimit
    }

    /// Sets the extra call data to pass to the hook.
    @discardableResult
    public mutating func data(_ callData: Data) -> Self {
        self.data = callData
        return self
    }

    /// Sets the maximum gas limit for the hook invocation.
    @discardableResult
    public mutating func gasLimit(_ gasLimit: UInt64) -> Self {
        self.gasLimit = gasLimit
        return self
    }
}

extension EvmHookCall: TryProtobufCodable {
    internal typealias Protobuf = Proto_EvmHookCall

    /// Construct from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        self.data = Data(proto.data)
        self.gasLimit = UInt64(proto.gasLimit)
    }

    /// Convert to protobuf.
    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.data = data
            proto.gasLimit = UInt64(gasLimit)
        }
    }
}

extension EvmHookCall: ValidateChecksums {
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        // EvmHookCall only contains Data and UInt64, no checksums to validate
    }
}
