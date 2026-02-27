// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The Hiero extension points that accept a hook.
///
/// Extension points define where in the transaction lifecycle a hook can be invoked.
/// Each extension point specifies a contract between the network and the hook's EVM bytecode,
/// including what parameters are passed and what return value is expected.
public enum HookExtensionPoint {
    /// Used to customize an account's allowances during a `CryptoTransfer` transaction.
    ///
    /// When referenced in a transfer, the hook's EVM bytecode is called with the proposed
    /// transfers. The hook must return `true` for the transfer to proceed.
    case accountAllowanceHook
}

extension HookExtensionPoint: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_HookExtensionPoint

    internal init(protobuf proto: Protobuf) throws {
        switch proto {
        case .accountAllowanceHook:
            self = .accountAllowanceHook
        case .UNRECOGNIZED(let code):
            throw HError.fromProtobuf("unrecognized HookExtensionPoint `\(code)`")
        }
    }

    internal func toProtobuf() -> Protobuf {
        switch self {
        case .accountAllowanceHook:
            return .accountAllowanceHook
        }
    }
}
