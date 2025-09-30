// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Specifies the details of a call to an EVM hook.
public struct EvmHookCall {
    /// The call data to pass to the hook.
    public var data: Data

    /// The gas limit to use.
    public var gasLimit: UInt64

    public init(data: Data = Data(), gasLimit: UInt64 = 0) {
        self.data = data
        self.gasLimit = gasLimit
    }

    /// Set the call data to pass to the hook.
    @discardableResult
    public mutating func data(_ callData: Data) -> Self {
        self.data = callData
        return self
    }

    /// Set the gas limit for the hook.
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
