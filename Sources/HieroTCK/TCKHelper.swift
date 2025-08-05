// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Represents all supported JSON-RPC method names.
///
/// Each case corresponds to a specific method string expected from incoming JSON-RPC requests.
/// Used to match requests with their appropriate handlers during routing.
internal enum JSONRPCMethod: String {
    case approveAllowance = "approveAllowance"
    case associateToken = "associateToken"
    case burnToken = "burnToken"
    case createAccount = "createAccount"
    case createToken = "createToken"
    case deleteAccount = "deleteAccount"
    case deleteAllowance = "deleteAllowance"
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
    case transferCrypto = "transferCrypto"
    case unfreezeToken = "unfreezeToken"
    case unpauseToken = "unpauseToken"
    case updateAccount = "updateAccount"
    case updateTokenFeeSchedule = "updateTokenFeeSchedule"
    case updateToken = "updateToken"
    case unsupported

    /// Attempts to parse a string into a corresponding `JSONRPCMethod` enum value.
    ///
    /// If the method name is not recognized, `.unsupported` is returned to allow graceful fallback handling.
    ///
    /// - Parameters:
    ///   - method: The method string from the incoming JSON-RPC request.
    /// - Returns: A `JSONRPCMethod` enum value representing the parsed method.
    internal static func method(named method: String) -> JSONRPCMethod {
        return JSONRPCMethod(rawValue: method) ?? .unsupported
    }
}

/// Attempts to convert a `String` into a fixed-width integer of the specified type.
///
/// Commonly used to extract and validate integer parameters from JSON-RPC input.
/// Provides a descriptive error message on failure.
///
/// - Parameters:
///   - name: The name of the parameter (used in error reporting).
///   - str: The string to convert.
///   - funcName: The name of the JSON-RPC method (used in error reporting).
/// - Returns: The converted value of type `T`.
/// - Throws: `JSONError.invalidParams` if the string is not a valid integer of type `T`.
internal func toInt<T: FixedWidthInteger>(name: String, from str: String, for funcName: JSONRPCMethod) throws -> T {
    return try T(str)
        ?? {
            throw JSONError.invalidParams(
                "\(funcName.rawValue): '\(str)' for parameter '\(name)' is not a valid \(T.self).")
        }()
}

/// Converts a signed `Int64` into an unsigned `UInt64`, preserving bit pattern.
///
/// This is useful when external inputs (e.g., TCK test cases) specify signed values
/// that must be interpreted as unsigned for compatibility with SDK-level APIs.
///
/// - Parameters:
///   - int: The signed 64-bit integer to convert.
/// - Returns: The resulting `UInt64` with the same bit representation.
internal func toUint64(_ int: Int64) -> UInt64 {
    return UInt64(truncatingIfNeeded: int)
}
