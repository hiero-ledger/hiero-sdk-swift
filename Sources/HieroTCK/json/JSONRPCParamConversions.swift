// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Higher-level parameter **conversion** and **optional-handling** helpers.
///
/// `JSONRPCParam` builds on top of values already extracted by `JSONRPCParser`.
/// It converts primitive inputs (typically strings) into the exact types your
/// business logic needs (e.g., string -> `Int64`/`UInt64`, string -> UTF-8 `Data`,
/// signed <-> unsigned bit-pattern reinterpretation), and provides `…IfPresent`
/// variants for optional fields.
///
/// This layer assumes you already located the parameter in the JSON and now need
/// a precise, validated conversion or conditional assignment.
///
/// Example:
/// ```swift
/// // After extracting:
/// let amountStr: String = try JSONRPCParser.getRequiredParameter(
///     name: "amount",
///     from: params,
///     for: method)
///
/// // Convert string -> UInt64:
/// let amount: UInt64 = try JSONRPCParam.parseUInt64(
///     name: "amount",
///     from: amountStr,
///     for: method)
///
/// // Optional UTF-8 memo:
/// let memoData: Data? = try JSONRPCParam.parseUtf8DataIfPresent(
///     name: "memo",
///     from: try JSONRPCParser.getOptionalParameterIfPresent(
///         name: "memo",
///         from: params,
///         for: method),
///     for: method)
///
/// // Conditionally assign:
/// memoData.assign(to: &tx.memo)
/// ```
internal enum JSONRPCParam {

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
    internal static func parseInt64(name: String, from str: String, for method: JSONRPCMethod) throws -> Int64 {
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
    internal static func parseInt64IfPresent(
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
    internal static func parseUInt64(name: String, from str: String, for method: JSONRPCMethod) throws -> UInt64 {
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
    internal static func parseUInt64IfPresent(
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
    internal static func parseUInt64ReinterpretingSigned(
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
    internal static func parseUInt64IfPresentReinterpretingSigned(
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
    internal static func parseInt64ReinterpretingUnsigned(
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
    internal static func parseInt64IfPresentReinterpretingUnsigned(
        name: String,
        from param: String?,
        for method: JSONRPCMethod
    ) throws -> Int64? {
        try param.map { try parseInt64ReinterpretingUnsigned(name: name, from: $0, for: method) }
    }

    // MARK: - Data Parsing

    /// Parses an optional JSON-RPC string into UTF-8–encoded `Data`.
    ///
    /// - Parameters:
    ///   - name: The parameter name, used in error reporting.
    ///   - param: An optional string to parse.
    ///   - method: The JSON-RPC method name, used in error reporting.
    /// - Returns: UTF-8–encoded `Data` if the string is present and valid; otherwise `nil`.
    /// - Throws: `JSONError.invalidParams` if the string is present but not valid UTF-8.
    internal static func parseUtf8DataIfPresent(
        name: String,
        from param: String?,
        for method: JSONRPCMethod
    ) throws -> Data? {
        try param.map { try parseUtf8Data(name: name, from: $0, for: method) }
    }

    /// Parses a required JSON-RPC string into UTF-8–encoded `Data`.
    ///
    /// - Parameters:
    ///   - name: The parameter name, used in error reporting.
    ///   - param: The string to parse.
    ///   - method: The JSON-RPC method name, used in error reporting.
    /// - Returns: UTF-8–encoded `Data`.
    /// - Throws: `JSONError.invalidParams` if the string is not valid UTF-8.
    internal static func parseUtf8Data(
        name: String,
        from param: String,
        for method: JSONRPCMethod
    ) throws -> Data {
        guard let data = param.data(using: .utf8) else {
            throw JSONError.invalidParams("\(method.rawValue): \(name) MUST be a UTF-8 string.")
        }
        return data
    }

    // MARK: - Enums

    internal static func parseEnum<T>(name: String, from s: String, map: [String: T], for method: JSONRPCMethod) throws
        -> T
    {
        if let v = map[s] { return v }
        throw JSONError.invalidParams("\(method.rawValue): \(name) MUST be one of \(Array(map.keys)).")
    }

    internal static func parseEnumIfPresent<T>(
        name: String, from s: String?, map: [String: T], for method: JSONRPCMethod
    ) throws -> T? {
        try s.map { try parseEnum(name: name, from: $0, map: map, for: method) }
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
    private static func parseInteger<T: FixedWidthInteger>(
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
}
