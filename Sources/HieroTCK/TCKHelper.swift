// SPDX-License-Identifier: Apache-2.0

import Hiero

// MARK: - JSON-RPC Method Names

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
    /// - Parameter method: The method string from the incoming JSON-RPC request.
    /// - Returns: A `JSONRPCMethod` value, or `.unsupported` if not recognized.
    internal static func method(named method: String) -> JSONRPCMethod {
        JSONRPCMethod(rawValue: method) ?? .unsupported
    }
}

// MARK: - Integer Parsing (Typed Wrappers)

/// Parses a base-10 integer string into a signed 64-bit integer (`Int64`).
///
/// This is a typed convenience wrapper around `parseInteger` for the common case
/// where the target type is `Int64`. It validates that the input is a valid base-10
/// representation within the range of `Int64`, and produces a descriptive error on failure.
///
/// - Parameters:
///   - name: The parameter name, used in error messages.
///   - str: The base-10 integer string to parse.
///   - method: The JSON-RPC method name, used in error messages.
/// - Returns: The parsed `Int64` value.
/// - Throws: `JSONError.invalidParams` if the string is not a valid `Int64`.
internal func parseInt64(name: String, from str: String, for method: JSONRPCMethod) throws -> Int64 {
    try parseInteger(name: name, from: str, for: method)
}

/// Parses an optional base-10 integer string into a signed 64-bit integer (`Int64`).
///
/// If `param` is `nil`, this returns `nil` without attempting to parse.
/// If `param` is non-nil, it behaves like `parseInt64`, validating that the string
/// is a base-10 integer within the range of `Int64`, and throwing a descriptive error on failure.
///
/// - Parameters:
///   - name: The parameter name, used in error messages.
///   - param: The optional base-10 integer string to parse.
///   - method: The JSON-RPC method name, used in error messages.
/// - Returns: The parsed `Int64` value, or `nil` if `param` is `nil`.
/// - Throws: `JSONError.invalidParams` if `param` is non-nil and not a valid `Int64`.
internal func parseInt64IfPresent(
    name: String,
    from param: String?,
    for method: JSONRPCMethod
) throws -> Int64? {
    try param.map { try parseInt64(name: name, from: $0, for: method) }
}

/// Parses a base-10 integer string into an unsigned 64-bit integer (`UInt64`).
///
/// This is a typed convenience wrapper around `parseInteger` for the common case
/// where the target type is `UInt64`. It validates that the input is a valid base-10
/// representation within the range of `UInt64`, and produces a descriptive error on failure.
///
/// - Parameters:
///   - name: The parameter name, used in error messages.
///   - str: The base-10 integer string to parse.
///   - method: The JSON-RPC method name, used in error messages.
/// - Returns: The parsed `UInt64` value.
/// - Throws: `JSONError.invalidParams` if the string is not a valid `UInt64`.
internal func parseUInt64(name: String, from str: String, for method: JSONRPCMethod) throws -> UInt64 {
    try parseInteger(name: name, from: str, for: method)
}

/// Parses an optional base-10 integer string into an unsigned 64-bit integer (`UInt64`).
///
/// If `param` is `nil`, this returns `nil` without attempting to parse.
/// If `param` is non-nil, it behaves like `parseUInt64`, validating that the string
/// is a base-10 integer within the range of `UInt64`, and throwing a descriptive error on failure.
///
/// - Parameters:
///   - name: The parameter name, used in error messages.
///   - param: The optional base-10 integer string to parse.
///   - method: The JSON-RPC method name, used in error messages.
/// - Returns: The parsed `UInt64` value, or `nil` if `param` is `nil`.
/// - Throws: `JSONError.invalidParams` if `param` is non-nil and not a valid `UInt64`.
internal func parseUInt64IfPresent(
    name: String,
    from param: String?,
    for method: JSONRPCMethod
) throws -> UInt64? {
    try param.map { try parseUInt64(name: name, from: $0, for: method) }
}

// MARK: - Integer Parsing (Bit-Pattern Reinterpretation)

/// Parses a base-10 integer string as a signed 64-bit integer (`Int64`) and reinterprets its
/// two's-complement bit pattern as an unsigned 64-bit integer (`UInt64`).
///
/// This preserves the raw bit pattern without performing a numerical sign conversion.
/// For example, the string `"-1"` will produce `UInt64.max`.
///
/// **Use this only** when external inputs intentionally provide signed integer values
/// that must be treated as their unsigned two's-complement representation for low-level
/// protocol or compatibility purposes.
///
/// - Parameters:
///   - name: The parameter name, used in error messages.
///   - str: The base-10 integer string to parse as `Int64`.
///   - method: The JSON-RPC method name, used in error messages.
/// - Returns: The unsigned integer with the same bit pattern as the parsed `Int64`.
/// - Throws: `JSONError.invalidParams` if the string is not a valid `Int64`.
internal func parseUInt64ReinterpretingSigned(
    name: String,
    from str: String,
    for method: JSONRPCMethod
) throws -> UInt64 {
    guard let signed = Int64(str) else {
        throw JSONError.invalidParams(
            "\(method.rawValue): '\(str)' for parameter '\(name)' is not a valid Int64 for bit-pattern reinterpretation."
        )
    }
    return UInt64(bitPattern: signed)
}

/// Parses an optional base-10 integer string as a signed 64-bit integer (`Int64`)
/// and reinterprets its two's-complement bit pattern as an unsigned 64-bit integer (`UInt64`).
///
/// If `param` is `nil`, this returns `nil` without attempting to parse.
/// If `param` is non-nil, it is parsed the same way as `parseUInt64ReinterpretingSigned`.
///
/// - Parameters:
///   - name: The parameter name, used in error messages.
///   - param: The optional base-10 integer string to parse.
///   - method: The JSON-RPC method name, used in error messages.
/// - Returns: The unsigned integer with the same bit pattern as the parsed `Int64`,
///            or `nil` if `param` is `nil`.
/// - Throws: `JSONError.invalidParams` if `param` is non-nil and not a valid `Int64`.
internal func parseUInt64IfPresentReinterpretingSigned(
    name: String,
    from param: String?,
    for method: JSONRPCMethod
) throws -> UInt64? {
    try param.map { try parseUInt64ReinterpretingSigned(name: name, from: $0, for: method) }
}

/// Parses a base-10 integer string as an unsigned 64-bit integer (`UInt64`) and
/// reinterprets its two's-complement bit pattern as a signed 64-bit integer (`Int64`).
///
/// This preserves the raw bits without performing a numerical sign conversion.
/// For example, the string `"18446744073709551615"` (`UInt64.max`) becomes `-1`.
///
/// **Use this only** when external inputs intentionally provide unsigned values
/// that must be treated as their signed two's-complement representation for low-level
/// protocol or compatibility purposes.
///
/// - Parameters:
///   - name: The parameter name, used in error messages.
///   - str: The base-10 integer string to parse as `UInt64`.
///   - method: The JSON-RPC method name, used in error messages.
/// - Returns: The signed integer with the same bit pattern as the parsed `UInt64`.
/// - Throws: `JSONError.invalidParams` if the string is not a valid `UInt64`.
internal func parseInt64ReinterpretingUnsigned(
    name: String,
    from str: String,
    for method: JSONRPCMethod
) throws -> Int64 {
    guard let unsigned = UInt64(str) else {
        throw JSONError.invalidParams(
            "\(method.rawValue): '\(str)' for parameter '\(name)' is not a valid UInt64 for bit-pattern reinterpretation."
        )
    }
    return Int64(bitPattern: unsigned)
}

/// Parses an optional base-10 integer string as an unsigned 64-bit integer (`UInt64`)
/// and reinterprets its two's-complement bit pattern as a signed 64-bit integer (`Int64`).
///
/// If `param` is `nil`, this returns `nil` without attempting to parse.
/// If `param` is non-nil, it behaves like `parseInt64ReinterpretingUnsigned`.
///
/// - Parameters:
///   - name: The parameter name, used in error messages.
///   - param: The optional base-10 integer string to parse as `UInt64`.
///   - method: The JSON-RPC method name, used in error messages.
/// - Returns: The signed integer with the same bit pattern as the parsed `UInt64`,
///            or `nil` if `param` is `nil`.
/// - Throws: `JSONError.invalidParams` if `param` is non-nil and not a valid `UInt64`.
internal func parseInt64IfPresentReinterpretingUnsigned(
    name: String,
    from param: String?,
    for method: JSONRPCMethod
) throws -> Int64? {
    try param.map { try parseInt64ReinterpretingUnsigned(name: name, from: $0, for: method) }
}

// MARK: - Small Utilities

/// Assigns a value to a target only if the value is non-nil.
///
/// Use this when:
/// - Trying to set an optional JSON-RPC parameter to a required SDK field.
/// - The type of the value and the target are the same.
/// - No additional parsing, conversion, or transformation is required.
///
/// For cases where the value requires translation (e.g. parsing a string to a model type),
/// use the appropriate conversion helper instead.
///
/// - Parameters:
///   - target: The variable or property to update.
///   - newValue: The optional value to assign if present.
internal func setIfPresent<T>(_ target: inout T, to newValue: T?) {
    if let newValue {
        target = newValue
    }
}

// MARK: - Core Generic (Implementation Detail)

/// Parses a base-10 integer string into a fixed-width integer of type `T`.
///
/// Validates that the string represents a whole number in base-10 within the range of `T`.
/// Produces a descriptive `JSONError.invalidParams` if parsing fails or the value is out of range.
///
/// - Parameters:
///   - name: The parameter name, used in error messages.
///   - str: The base-10 integer string to parse.
///   - method: The JSON-RPC method name, used in error messages.
/// - Returns: The parsed integer value of type `T`.
/// - Throws: `JSONError.invalidParams` if the string is not a valid, in-range integer of type `T`.
private func parseInteger<T: FixedWidthInteger>(
    name: String,
    from str: String,
    for method: JSONRPCMethod
) throws -> T {
    guard let v = T(str) else {
        throw JSONError.invalidParams(
            "\(method.rawValue): '\(str)' for parameter '\(name)' is not a valid \(T.self)."
        )
    }
    return v
}
