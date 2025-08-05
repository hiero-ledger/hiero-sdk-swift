// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Utility for extracting and transforming common JSON-RPC parameters into SDK-compatible types.
///
/// This enum provides static helper functions to convert raw JSON-RPC string values into
/// Hiero-specific domain types such as `AccountId`, `TokenId`, `Duration`, `Timestamp`, and numeric values.
/// These functions are used across multiple transaction parameter structs to streamline parsing logic.
///
/// - Note: All functions are stateless and safe to call independently. Most operate on optional input and
///         return `nil` if the input is `nil`. Validation and range enforcement are delegated to the SDK or downstream logic.
/// - Throws: `JSONError.invalidParams` if a present value is malformed or fails conversion.
internal enum CommonParamsParser {

    // MARK: - Entity Identifiers

    /// Parses an optional JSON-RPC string into a Hiero `AccountId`.
    ///
    /// - Parameters:
    ///   - param: A JSON-RPC string representing an account ID, or `nil`.
    /// - Returns: A parsed `AccountId`, or `nil` if the input is `nil`.
    /// - Throws: `HError.basicParse` if the string is non-nil but invalid.
    static internal func getAccountIdIfPresent(from param: String?) throws -> AccountId? {
        return try param.flatMap { try AccountId.fromString($0) }
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
        return try param?.map { try TokenId.fromString($0) }
    }

    // MARK: - Numeric Values

    /// Parses an optional JSON-RPC string into a `UInt64` amount.
    ///
    /// - Parameters:
    ///   - param: A string representing the amount, or `nil`.
    ///   - funcName: The JSON-RPC method name, used for error context.
    /// - Returns: A parsed `UInt64` value, or `nil` if the input is `nil`.
    /// - Throws: `JSONError.invalidParams` if the string is non-nil but not a valid integer.
    static internal func getAmountIfPresent(from param: String?, for funcName: JSONRPCMethod) throws -> UInt64? {
        return try param.flatMap { try toInt(name: "amount", from: $0, for: funcName) }
    }

    /// Parses a required JSON-RPC string into an `Int64` numerator.
    ///
    /// - Parameters:
    ///   - param: A non-optional string expected to represent an integer numerator.
    ///   - funcName: The name of the JSON-RPC method for contextual error reporting.
    /// - Returns: The parsed value as an `Int64`.
    /// - Throws: `JSONError.invalidParams` if the string cannot be parsed as a valid integer.
    static internal func getNumerator(from param: String, for funcName: JSONRPCMethod) throws -> Int64 {
        return try toInt(name: "numerator", from: param, for: funcName)
    }

    /// Parses a required JSON-RPC string into an `Int64` denominator.
    ///
    /// - Parameters:
    ///   - param: A non-optional string expected to represent an integer denominator.
    ///   - funcName: The name of the JSON-RPC method for contextual error reporting.
    /// - Returns: The parsed value as an `Int64`.
    /// - Throws: `JSONError.invalidParams` if the string cannot be parsed as a valid integer.
    static internal func getDenominator(from param: String, for funcName: JSONRPCMethod) throws -> Int64 {
        return try toInt(name: "denominator", from: param, for: funcName)
    }

    /// Parses an optional numeric string into a `UInt64`, truncating if necessary.
    ///
    /// - Parameters:
    ///   - param: A numeric string to convert, or `nil`.
    ///   - name: The name of the parameter, used in error messages.
    ///   - funcName: The JSON-RPC method name, used for error context.
    /// - Returns: A `UInt64` if the string is present and valid; otherwise `nil`.
    /// - Throws: `JSONError.invalidParams` if the string cannot be parsed.
    static internal func getSdkUInt64IfPresent(name: String, from param: String?, for funcName: JSONRPCMethod) throws
        -> UInt64?
    {
        return try param.flatMap { toUint64(try toInt(name: name, from: $0, for: funcName)) }
    }

    // MARK: - Time Values

    /// Parses an optional JSON-RPC string into a `Duration` representing the auto-renew period.
    ///
    /// - Parameters:
    ///   - param: A string representing the auto-renew period in seconds, or `nil`.
    ///   - funcName: The JSON-RPC method name, used for contextual error reporting.
    /// - Returns: A `Duration` if the string is valid, or `nil` if `param` is `nil`.
    /// - Throws: `JSONError.invalidParams` if the string is not a valid integer.
    static internal func getAutoRenewPeriodIfPresent(from param: String?, for funcName: JSONRPCMethod) throws
        -> Duration?
    {
        return try param.flatMap {
            Duration(seconds: toUint64(try toInt(name: "autoRenewPeriod", from: $0, for: funcName)))
        }
    }

    /// Parses an optional JSON-RPC string into a `Timestamp` expiration time.
    ///
    /// Converts a string value into a `Timestamp` with second-level precision (sub-second nanos default to 0).
    ///
    /// - Parameters:
    ///   - param: An optional string expected to represent an integer timestamp in seconds.
    ///   - funcName: The name of the JSON-RPC method for contextual error reporting.
    /// - Returns: A `Timestamp` if the input is present and valid, or `nil` if the input is `nil`.
    /// - Throws: `JSONError.invalidParams` if the input string cannot be parsed as a valid integer.
    static internal func getExpirationTimeIfPresent(from param: String?, for funcName: JSONRPCMethod) throws
        -> Timestamp?
    {
        return try param.flatMap {
            Timestamp(seconds: toUint64(try toInt(name: "expirationTime", from: $0, for: funcName)), subSecondNanos: 0)
        }
    }

    // MARK: - Staking / Signing

    /// Parses an optional JSON-RPC string into a `UInt64` staked node ID.
    ///
    /// - Parameters:
    ///   - param: A string representing the node ID, or `nil`.
    ///   - funcName: The JSON-RPC method name, used for error context.
    /// - Returns: A `UInt64` if the string is present and valid; otherwise `nil`.
    /// - Throws: `JSONError.invalidParams` if the input is malformed.
    static internal func getStakedNodeIdIfPresent(from param: String?, for funcName: JSONRPCMethod) throws -> UInt64? {
        try param.flatMap { toUint64(try toInt(name: "stakedNodeId", from: $0, for: funcName)) }
    }

    /// Parses an optional JSON-RPC string into a `Hiero.Key`.
    ///
    /// - Parameters:
    ///   - param: A string representing the key, or `nil`.
    /// - Returns: A `Hiero.Key` if the string is present and valid; otherwise `nil`.
    /// - Throws: If key parsing fails.
    static internal func getKeyIfPresent(from param: String?) throws -> Hiero.Key? {
        return try param.flatMap { try KeyService.service.getHieroKey(from: $0) }
    }

    // MARK: - Fees

    /// Parses an optional list of custom fee parameter objects into Hiero SDK-compatible `AnyCustomFee` types.
    ///
    /// - Parameters:
    ///   - param: An optional list of parsed `CustomFee` structs from JSON-RPC input.
    ///   - funcName: The JSON-RPC method name, used for contextual error reporting during transformation.
    /// - Returns: A list of `Hiero.AnyCustomFee` instances, or `nil` if `param` is `nil`.
    /// - Throws: `JSONError.invalidParams` if any fee entry fails to convert.
    static internal func getCustomFeesIfPresent(from param: [CustomFee]?, for funcName: JSONRPCMethod) throws -> [Hiero
        .AnyCustomFee]?
    {
        return try param?.map { try $0.toHieroCustomFee(for: funcName) }
    }
}
