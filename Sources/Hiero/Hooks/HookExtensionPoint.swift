// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

public enum HookExtensionPoint {
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
