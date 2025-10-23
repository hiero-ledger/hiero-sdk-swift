// SPDX-License-Identifier: Apache-2.0

// MARK: JSONRPCParser

/// Low-level extraction utilities for JSON-RPC parameters.
///
/// `JSONRPCParser` reads raw values out of `JSONObject` trees and parameter dictionaries,
/// validates their presence/shape, and converts them into **Swift primitives/containers**
/// (e.g., `String`, `Int64`, `UInt64`, `Bool`, `[JSONObject]`, `[String: JSONObject]`).
///
/// It enforces JSON-RPC 2.0 expectations (required vs. optional, array vs. object),
/// and throws `JSONError.invalidParams` when fields are missing or of the wrong type.
///
/// This layer **does not** perform domain-specific conversions (e.g., string->Hiero IDs,
/// bit-pattern reinterpretation, UTF-8 encoding). For those, use `JSONRPCParam`.
///
/// Example:
/// ```swift
/// // Pull a required string field from the params dictionary:
/// let amountStr: String = try JSONRPCParser.getRequiredParameter(
///     name: "amount",
///     from: params,
///     for: method)
///
/// // Pull an optional list of JSON objects:
/// let items: [JSONObject]? = try JSONRPCParser.getOptionalParameterIfPresent(
///     name: "items",
///     from: params,
///     for: method)
///
/// // Decode a list of custom elements with index-aware errors:
/// let transfers: [Transfer] = try JSONRPCParser.getRequiredCustomObjectList(
///     name: "tokenTransfers",
///     from: params,
///     for: method,
///     decoder: Transfer.indexDecoder(for: method))
/// ```
internal enum JSONRPCParser {

    // MARK: - Required Parameters

    /// Extracts and decodes a required parameter from a JSON-RPC parameters dictionary.
    ///
    /// - Parameters:
    ///   - name: The name of the required parameter.
    ///   - parameters: The JSON-RPC parameters dictionary (already parsed as `[String: JSONObject]`).
    ///   - method: The name of the JSON-RPC method (used for contextual error reporting).
    /// - Returns: The decoded value of type `T`.
    /// - Throws: `JSONError.invalidParams` if the parameter is missing or cannot be decoded into type `T`.
    internal static func getRequiredParameter<T>(
        name: String,
        from parameters: [String: JSONObject],
        for method: JSONRPCMethod
    ) throws -> T {
        return try getJson(
            name: name,
            from: parameters[name] ?? { throw JSONError.invalidParams("\(method): \(name) MUST be provided.") }(),
            for: method)
    }

    /// Extracts the top-level `"params"` object from a JSON-RPC request, ensuring it is present.
    ///
    /// - Parameters:
    ///   - request: The full JSON-RPC request object.
    /// - Returns: A dictionary of parameters (`[String: JSONObject]`) extracted from the `"params"` field.
    /// - Throws: `JSONError.invalidParams` if the `"params"` field is missing or malformed.
    internal static func getRequiredRequestParams(request: JSONRequest) throws -> [String: JSONObject] {
        return try getRequiredParameter(
            name: "params",
            from: request.toDict(),
            for: JSONRPCMethod.method(named: request.method))
    }

    /// Extracts a required JSON parameter expected to be a list of primitive values
    /// (i.e. values parseable by getJson()), and parses each element into type `T`.
    ///
    /// - Parameters:
    ///   - name: The name of the required parameter.
    ///   - parameters: The JSON-RPC parameters dictionary.
    ///   - method: The name of the JSON-RPC method (for error context).
    /// - Returns: An array of parsed values of type `T`.
    /// - Throws: `JSONError.invalidParams` if the parameter is missing, not a list, or contains invalid values.
    internal static func getRequiredPrimitiveList<T>(
        name: String,
        from parameters: [String: JSONObject],
        for method: JSONRPCMethod
    ) throws -> [T] {
        let list: [JSONObject] = try getRequiredParameter(name: name, from: parameters, for: method)
        return try list.enumerated().map {
            try getJson(name: "\(name)[\($0.offset)]", from: $0.element, for: method) as T
        }
    }

    /// Extracts and parses a required JSON parameter as a list of custom objects,
    /// using the provided transformation closure for each item.
    ///
    /// - Parameters:
    ///   - name: The name of the required parameter.
    ///   - parameters: The JSON-RPC parameters dictionary.
    ///   - method: The name of the JSON-RPC method (for error context).
    ///   - decoder: A function to decode each `JSONObject` into a custom type.
    /// - Returns: An array of parsed custom objects.
    /// - Throws: `JSONError.invalidParams` if the parameter is missing, not a list, or contains invalid elements.
    internal static func getRequiredCustomObjectList<T>(
        name: String,
        from parameters: [String: JSONObject],
        for method: JSONRPCMethod,
        decoder: (Int, JSONObject) throws -> T
    ) throws -> [T] {
        let list: [JSONObject] = try getRequiredParameter(name: name, from: parameters, for: method)
        return try list.enumerated().map { try decoder($0.offset, $0.element) }
    }

    // MARK: - Optional Parameters

    /// Attempts to extract and decode an optional parameter from a JSON-RPC parameters dictionary.
    ///
    /// - Parameters:
    ///   - name: The name of the parameter to extract.
    ///   - parameters: The JSON-RPC parameters dictionary (already parsed as `[String: JSONObject]`).
    ///   - method: The name of the JSON-RPC method (used for contextual error reporting).
    /// - Returns: The decoded value of type `T`, or `nil` if the parameter is not present.
    /// - Throws: `JSONError.invalidParams` if the parameter is present but cannot be decoded into type `T`.
    internal static func getOptionalParameterIfPresent<T>(
        name: String,
        from parameters: [String: JSONObject],
        for method: JSONRPCMethod
    ) throws -> T? {
        return try parameters[name].flatMap { try getJson(name: name, from: $0, for: method) as T }
    }

    /// Attempts to extract the top-level `"params"` object from a JSON-RPC request, if present.
    ///
    /// - Parameters:
    ///   - request: The full JSON-RPC request object.
    /// - Returns: A dictionary of parameters (`[String: JSONObject]`), or `nil` if the `"params"` field is not present.
    /// - Throws: `JSONError.invalidParams` if the `"params"` field exists but is not a valid object.
    internal static func getOptionalRequestParamsIfPresent(request: JSONRequest) throws -> [String: JSONObject]? {
        return try getOptionalParameterIfPresent(
            name: "params",
            from: request.toDict(),
            for: JSONRPCMethod.method(named: request.method))
    }

    /// Attempts to extract an optional JSON parameter expected to be a list of primitive values
    /// (i.e. values parseable by getJson()), and parses each element into type `T`.
    ///
    /// - Parameters:
    ///   - name: The name of the parameter to extract.
    ///   - parameters: The JSON-RPC parameters dictionary.
    ///   - method: The name of the JSON-RPC method (for error context).
    /// - Returns: An optional array of parsed values of type `T`, or `nil` if the parameter is not present.
    /// - Throws: `JSONError.invalidParams` if the parameter exists but is not a list or contains invalid values.
    internal static func getOptionalPrimitiveListIfPresent<T>(
        name: String,
        from parameters: [String: JSONObject],
        for method: JSONRPCMethod
    ) throws -> [T]? {
        guard let list: [JSONObject] = try getOptionalParameterIfPresent(name: name, from: parameters, for: method)
        else { return nil }

        return try list.enumerated().map {
            try getJson(name: "\(name)[\($0.offset)]", from: $0.element, for: method) as T
        }
    }

    /// Attempts to extract and parse an optional JSON parameter as a list of strongly-typed custom objects.
    ///
    /// - Parameters:
    ///   - name: The name of the optional parameter.
    ///   - parameters: The JSON-RPC parameters.
    ///   - method: The name of the JSON-RPC method (for error context).
    ///   - decoder: A function to decode each `JSONObject` into a custom type.
    /// - Returns: An optional array of parsed custom objects, or `nil` if the parameter is not present.
    /// - Throws: `JSONError.invalidParams` if the parameter exists but is not a list or contains invalid elements.
    internal static func getOptionalCustomObjectListIfPresent<T>(
        name: String,
        from parameters: [String: JSONObject],
        for method: JSONRPCMethod,
        decoder: (Int, JSONObject) throws -> T
    ) throws -> [T]? {
        let list: [JSONObject]? = try getOptionalParameterIfPresent(name: name, from: parameters, for: method)
        return try list?.enumerated().map { try decoder($0.offset, $0.element) }
    }

    /// Attempts to extract and parse an optional JSON parameters as a strongly-typed custom objects.
    ///
    /// - Parameters:
    ///   - name: The name of the parameter.
    ///   - params: The JSON-RPC parameters.
    ///   - method: The method name, for error context.
    ///   - constructor: A throwing function that constructs the target type from a `[String: JSONObject]`.
    /// - Returns: The parsed value, or `nil` if the parameter is absent.
    /// - Throws: Rethrows any error from `constructor` if the parameter is present but parsing fails.
    internal static func getOptionalCustomObjectIfPresent<T>(
        name: String,
        from params: [String: JSONObject],
        for method: JSONRPCMethod,
        using constructor: ([String: JSONObject], JSONRPCMethod) throws -> T
    ) throws -> T? {
        guard
            let value: [String: JSONObject] = try JSONRPCParser.getOptionalParameterIfPresent(
                name: name,
                from: params,
                for: method)
        else {
            return nil
        }

        return try constructor(value, method)
    }

    // MARK: - Private Helpers

    /// Attempts to extract and decode a `JSONObject` into a supported primitive or structured type `T`.
    ///
    /// This function acts as a type-safe extractor for JSON-RPC parameters. It supports the following target types:
    /// - `String`
    /// - `Int32`, `UInt32`, `Int64`, `UInt64`
    /// - `Double`, `Float`
    /// - `Bool`
    /// - `[JSONObject]` (JSON array)
    /// - `[String: JSONObject]` (JSON object)
    ///
    /// - Note: This function does **not** support custom types. For custom struct decoding,
    ///         use `getRequiredCustomObjectList(...)`, `getOptionalCustomObjectList(...)`, or manual parsing.
    ///
    /// - Parameters:
    ///   - json: The `JSONObject` to convert.
    ///   - paramName: The name of the parameter being parsed (used in error messages).
    ///   - method: The name of the JSON-RPC method being executed (used in error messages).
    /// - Returns: A value of type `T` parsed from the input `json`.
    /// - Throws: `JSONError.invalidParams` if the value is missing or not of the expected type.
    private static func getJson<T>(name: String, from json: JSONObject, for method: JSONRPCMethod) throws -> T {
        let errorMessage = "Parameter \(name) in \(method.rawValue)"

        if T.self == String.self {
            return try require(json.stringValue, "\(errorMessage) MUST be a string.") as! T
        }
        if T.self == Int32.self {
            return Int32(truncatingIfNeeded: try require(json.intValue, "\(errorMessage) MUST be an int32.")) as! T
        }
        if T.self == UInt32.self {
            return UInt32(truncatingIfNeeded: try require(json.intValue, "\(errorMessage) MUST be a uint32.")) as! T
        }
        if T.self == Int64.self {
            return try require(json.intValue, "\(errorMessage) MUST be an int64.") as! T
        }
        if T.self == UInt64.self {
            return UInt64(truncatingIfNeeded: try require(json.intValue, "\(errorMessage) MUST be a uint64.")) as! T
        }
        if T.self == Int.self {
            return Int(truncatingIfNeeded: try require(json.intValue, "\(errorMessage) MUST be an int.")) as! T
        }
        if T.self == Double.self || T.self == Float.self {
            return try require(json.doubleValue, "\(errorMessage) MUST be a double.") as! T
        }
        if T.self == Bool.self {
            return try require(json.boolValue, "\(errorMessage) MUST be a boolean.") as! T
        }
        if T.self == [JSONObject].self {
            return try require(json.listValue, "\(errorMessage) MUST be a list.") as! T
        }
        if T.self == [String: JSONObject].self {
            return try require(json.dictValue, "\(errorMessage) MUST be a dictionary.") as! T
        }

        throw JSONError.invalidParams("\(errorMessage) has unsupported type: \(T.self)")
    }

    /// Requires a non-nil value, or throws a `JSONError.invalidParams` with a provided message.
    ///
    /// This helper enforces the presence of a value during JSON parsing. If the value is `nil`,
    /// the function throws an error with the specified message. Used to make precondition checks more concise.
    ///
    /// - Parameters:
    ///   - value: The optional value to unwrap and validate.
    ///   - message: An autoclosure that returns the error message if `value` is nil.
    /// - Returns: The unwrapped value of type `T`.
    /// - Throws: `JSONError.invalidParams` with the given message if the value is missing.
    private static func require<T>(_ value: T?, _ message: @autoclosure () -> String) throws -> T {
        guard let value else { throw JSONError.invalidParams(message()) }
        return value
    }
}
