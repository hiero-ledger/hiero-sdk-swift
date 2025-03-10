// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Enumeration of implemented JSON-RPC endpoints.
internal enum JSONRPCMethod: String {
    case associateToken = "associateToken"
    case burnToken = "burnToken"
    case createAccount = "createAccount"
    case createToken = "createToken"
    case deleteAccount = "deleteAccount"
    case deleteToken = "deleteToken"
    case dissociateToken = "dissociateToken"
    case freezeToken = "freezeToken"
    case generateKey = "generateKey"
    case grantTokenKyc = "grantTokenKyc"
    case mintToken = "mintToken"
    case pauseToken = "pauseToken"
    case reset = "reset"
    case revokeTokenKyc = "revokeTokenKyc"
    case setup = "setup"
    case unfreezeToken = "unfreezeToken"
    case unpauseToken = "unpauseToken"
    case updateAccount = "updateAccount"
    case updateTokenFeeSchedule = "updateTokenFeeSchedule"
    case updateToken = "updateToken"
    case undefinedMethod
}

/// Convert a String to an integer type.
internal func toInt<T: FixedWidthInteger>(_ str: String, _ parameterName: String, _ funcName: JSONRPCMethod) throws -> T
{
    return try T(str)
        ?? { throw JSONError.invalidParams("\(funcName.rawValue): \(parameterName) isn't a valid \(T.self).") }()
}

/// Convert an Int64 to a UInt64. Useful if the TCK test specification defines an Int64, but the associated SDK value is a UInt64.
internal func toUint64(_ int: Int64) -> UInt64 {
    return UInt64(truncatingIfNeeded: int)
}
