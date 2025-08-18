// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

/// Utility for extracting and transforming common JSON-RPC parameters into SDK-compatible types.
///
/// This enum provides static helper functions to convert raw JSON-RPC string values into
/// Hiero-specific domain types such as `AccountId`, `TokenId`, `Duration`, `Timestamp`, and numeric values.
/// These functions are used across multiple transaction parameter structs to streamline parsing logic.
///
/// - Note: All functions are stateless and safe to call independently. Most operate on optional input and
///         return `nil` if the input is `nil`.
///
/// Validation and range enforcement are delegated to the SDK or downstream logic.
internal enum CommonParamsParser {

    // MARK: - Entity Identifiers

    /// Parses an optional JSON-RPC string into a Hiero `AccountId`.
    ///
    /// - Parameters:
    ///   - param: A JSON-RPC string representing an account ID, or `nil`.
    /// - Returns: A parsed `AccountId`, or `nil` if the input is `nil`.
    /// - Throws: `HError.basicParse` if the string is non-nil but invalid.
    static internal func getAccountIdIfPresent(from param: String?) throws -> AccountId? {
        try param.flatMap { try AccountId.fromString($0) }
    }

    /// Parses an optional JSON-RPC string into a `TokenId`.
    ///
    /// - Parameters:
    ///   - param: A string representing a token ID, or `nil`.
    /// - Returns: A `TokenId` if the string is present and valid; otherwise `nil`.
    /// - Throws: If the token ID format is invalid.
    static internal func getTokenIdIfPresent(from param: String?) throws -> TokenId? {
        try param.flatMap { try TokenId.fromString($0) }
    }

    /// Parses an optional JSON-RPC list strings into `TokenIds`.
    ///
    /// - Parameters:
    ///   - param: An array of strings representing token IDs, or `nil`.
    /// - Returns: An array of `TokenId` values if present and valid; otherwise `nil`.
    /// - Throws: If any of the token ID strings are invalid.
    static internal func getTokenIdsIfPresent(from param: [String]?) throws -> [TokenId]? {
        try param?.map { try TokenId.fromString($0) }
    }

    // MARK: - Numeric Values

    /// Parses an optional JSON-RPC string into a `UInt64` amount.
    ///
    /// - Parameters:
    ///   - param: A string representing the amount, or `nil`.
    ///   - method: The JSON-RPC method name, used for error context.
    /// - Returns: A parsed `UInt64` value, or `nil` if the input is `nil`.
    /// - Throws: `JSONError.invalidParams` if the string is non-nil but not a valid integer.
    static internal func getAmountIfPresent(from param: String?, for method: JSONRPCMethod) throws -> UInt64? {
        try param.flatMap { try parseUInt64(name: "amount", from: $0, for: method) }
    }

    /// Parses a required JSON-RPC string into an amount, using the specified parsing function.
    ///
    /// This is a convenience wrapper that fixes the parameter name to `"amount"` so callers
    /// only need to supply the value, the JSON-RPC method name, and a parsing function.
    /// The parsing function can be any of the existing helpers (e.g., `parseInt64`,
    /// `parseUInt64ReinterpretingSigned`) or a custom closure with the matching signature.
    ///
    /// - Parameters:
    ///   - param: The raw string value of the `"amount"` parameter.
    ///   - method: The JSON-RPC method name, used for error reporting.
    ///   - parser: A function or closure that parses the parameter into the desired type.
    ///             It must accept `(name, value, method)` and return the parsed value or throw.
    /// - Returns: The parsed amount value of type `T`.
    /// - Throws: Any error thrown by the `parser`, such as `JSONError.invalidParams` for invalid inputs.
    static internal func getAmount<T>(
        from param: String,
        for method: JSONRPCMethod,
        using parser: (String, String, JSONRPCMethod) throws -> T
    ) rethrows -> T {
        try parser("amount", param, method)
    }

    /// Parses a required JSON-RPC string into an `Int64` numerator.
    ///
    /// - Parameters:
    ///   - param: A non-optional string expected to represent an integer numerator.
    ///   - method: The name of the JSON-RPC method for contextual error reporting.
    /// - Returns: The parsed value as an `Int64`.
    /// - Throws: `JSONError.invalidParams` if the string cannot be parsed as a valid integer.
    static internal func getNumerator(from param: String, for method: JSONRPCMethod) throws -> Int64 {
        try parseInt64(name: "numerator", from: param, for: method)
    }

    /// Parses a required JSON-RPC string into an `Int64` denominator.
    ///
    /// - Parameters:
    ///   - param: A non-optional string expected to represent an integer denominator.
    ///   - method: The name of the JSON-RPC method for contextual error reporting.
    /// - Returns: The parsed value as an `Int64`.
    /// - Throws: `JSONError.invalidParams` if the string cannot be parsed as a valid integer.
    static internal func getDenominator(from param: String, for method: JSONRPCMethod) throws -> Int64 {
        try parseInt64(name: "denominator", from: param, for: method)
    }

    /// Parses a serial number string into a `UInt64`.
    ///
    /// The input string is parsed as a signed 64-bit integer (`Int64`) and its
    /// two’s-complement bit pattern is reinterpreted as an unsigned 64-bit integer (`UInt64`),
    /// for compatibility with SDK-level APIs.
    ///
    /// The optional `index` parameter is used only for error reporting. When serial numbers
    /// are provided as part of a list in a JSON-RPC request, including the index in error
    /// messages helps identify which element failed to parse (e.g. `"serial number[3]"`).
    ///
    /// - Parameters:
    ///   - param: The serial number string to parse.
    ///   - method: The JSON-RPC method name, used in error reporting.
    ///   - index: The position of this serial number in its list, if applicable (for error context).
    /// - Returns: The parsed serial number as a `UInt64`.
    /// - Throws: `JSONError.invalidParams` if the string is not a valid signed 64-bit integer.
    internal static func getSerialNumber(
        from param: String,
        for method: JSONRPCMethod,
        index: Int? = nil
    ) throws -> UInt64 {
        return try parseUInt64ReinterpretingSigned(
            name: index.map { "serial number[\($0)]" } ?? "serial number",
            from: param,
            for: method)
    }

    // MARK: - Time Values

    /// Parses an optional JSON-RPC string into a `Duration` representing the auto-renew period.
    ///
    /// - Parameters:
    ///   - param: A string representing the auto-renew period in seconds, or `nil`.
    ///   - method: The JSON-RPC method name, used for contextual error reporting.
    /// - Returns: A `Duration` if the string is valid, or `nil` if `param` is `nil`.
    /// - Throws: `JSONError.invalidParams` if the string is not a valid integer.
    static internal func getAutoRenewPeriodIfPresent(from param: String?, for method: JSONRPCMethod) throws
        -> Duration?
    {
        try param.flatMap {
            Duration(seconds: try parseUInt64ReinterpretingSigned(name: "autoRenewPeriod", from: $0, for: method))
        }
    }

    /// Parses an optional JSON-RPC string into a `Timestamp` expiration time.
    ///
    /// Converts a string value into a `Timestamp` with second-level precision (sub-second nanos default to 0).
    ///
    /// - Parameters:
    ///   - param: An optional string expected to represent an integer timestamp in seconds.
    ///   - method: The name of the JSON-RPC method for contextual error reporting.
    /// - Returns: A `Timestamp` if the input is present and valid, or `nil` if the input is `nil`.
    /// - Throws: `JSONError.invalidParams` if the input string cannot be parsed as a valid integer.
    static internal func getExpirationTimeIfPresent(from param: String?, for method: JSONRPCMethod) throws
        -> Timestamp?
    {
        try param.flatMap {
            Timestamp(
                seconds: try parseUInt64ReinterpretingSigned(name: "expirationTime", from: $0, for: method),
                subSecondNanos: 0)
        }
    }

    // MARK: - Staking / Signing

    /// Parses an optional JSON-RPC string into a `UInt64` staked node ID.
    ///
    /// - Parameters:
    ///   - param: A string representing the node ID, or `nil`.
    ///   - method: The JSON-RPC method name, used for error context.
    /// - Returns: A `UInt64` if the string is present and valid; otherwise `nil`.
    /// - Throws: `JSONError.invalidParams` if the input is malformed.
    static internal func getStakedNodeIdIfPresent(from param: String?, for method: JSONRPCMethod) throws -> UInt64? {
        try param.flatMap { try parseUInt64ReinterpretingSigned(name: "stakedNodeId", from: $0, for: method) }
    }

    /// Parses an optional JSON-RPC string into a Hiero `Key`.
    ///
    /// - Parameters:
    ///   - param: A string representing the key, or `nil`.
    /// - Returns: A Hiero `Key` if the string is present and valid; otherwise `nil`.
    /// - Throws: If key parsing fails.
    static internal func getKeyIfPresent(from param: String?) throws -> Key? {
        try param.flatMap { try KeyService.service.getHieroKey(from: $0) }
    }

    // MARK: - Fees

    /// Parses an optional list of custom fee parameter objects into Hiero `AnyCustomFee` types.
    ///
    /// - Parameters:
    ///   - param: An optional list of parsed `CustomFee` structs from JSON-RPC input.
    ///   - method: The JSON-RPC method name, used for contextual error reporting during transformation.
    /// - Returns: A list of Hiero `AnyCustomFee` instances, or `nil` if `param` is `nil`.
    /// - Throws: `JSONError.invalidParams` if any fee entry fails to convert.
    static internal func getCustomFeesIfPresent(from param: [CustomFee]?, for method: JSONRPCMethod) throws
        -> [AnyCustomFee]?
    {
        try param?.map { try $0.toHieroCustomFee(for: method) }
    }

    // MARK: - Metadata

    /// Parses a metadata string into UTF-8–encoded `Data`.
    ///
    /// It validates that the given string can be represented as UTF-8 and returns
    /// the corresponding `Data`. If validation fails, a descriptive error message
    /// is thrown that includes the JSON-RPC method name and parameter context.
    ///
    /// - Parameters:
    ///   - name: The parameter name, included in error messages (defaults to `"metadata"`).
    ///   - param: The metadata string to parse.
    ///   - method: The JSON-RPC method name, used in error reporting.
    /// - Returns: The UTF-8–encoded metadata as `Data`.
    /// - Throws: `JSONError.invalidParams` if the string is not valid UTF-8.
    static internal func parseMetadataString(name: String = "metadata", from param: String, for method: JSONRPCMethod)
        throws
        -> Data
    {
        guard let data = param.data(using: .utf8) else {
            throw JSONError.invalidParams("\(method.rawValue): \(name) MUST be a UTF-8 string.")
        }
        return data
    }

    /// Parses optional metadata from a JSON-RPC parameter into `Data`.
    ///
    /// If `param` is `nil`, this returns `nil` without attempting to parse.
    /// If `param` is non-nil, its `metadata` element is expected to be a UTF-8 encoded string.
    /// The string is converted to `Data` using UTF-8 encoding, and a descriptive error is thrown
    /// if the value is not valid UTF-8.
    ///
    /// - Parameters:
    ///   - param: An optional list of metadata strings from the JSON-RPC request.
    ///   - method: The JSON-RPC method name, used in error reporting.
    /// - Returns: The UTF-8–encoded metadata as `Data`, or `nil` if `param` is `nil`.
    /// - Throws: `JSONError.invalidParams` if `metadata` is present but not a valid UTF-8 string.
    static internal func getMetadataIfPresent(from param: String?, for method: JSONRPCMethod) throws -> Data? {
        try param.flatMap { try parseMetadataString(from: $0, for: method) }
    }
}
