// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Shared specifications of an EVM hook. May be used for any extension point.
public struct EvmHookSpec {
    /// The source of the EVM bytecode for the hook.
    public var contractId: ContractId?

    public init(contractId: ContractId? = nil) {
        self.contractId = contractId
    }

    /// Set the contract that contains the hook EVM bytecode. Resets other bytecode sources.
    @discardableResult
    public mutating func contractId(_ contractId: ContractId) -> Self {
        self.contractId = contractId
        return self
    }
}

extension EvmHookSpec: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_EvmHookSpec

    /// Construct from protobuf.
    internal init(protobuf proto: Protobuf) throws {
        // Handle the case where contractID might not be set
        if case .contractID(let contractID)? = proto.bytecodeSource {
            self.contractId = try ContractId.fromProtobuf(contractID)
        } else {
            self.contractId = nil
        }
    }

    /// Convert to protobuf.
    internal func toProtobuf() -> Protobuf {
        .with { proto in
            if let id = contractId {
                proto.bytecodeSource = .contractID(id.toProtobuf())
            }
        }
    }
}
