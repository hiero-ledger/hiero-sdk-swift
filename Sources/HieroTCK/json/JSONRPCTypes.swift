// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import Vapor

private let jsonRpcVersion = "2.0"

// MARK: - JSON-RPC Core

/// Represents an incoming JSON-RPC request compliant with JSON-RPC 2.0.
///
/// Handles deserialization and validation of required fields such as `jsonrpc`, `id`, and `method`,
/// with optional `params`. Supports numeric or string IDs (which are coerced to `Int`).
///
/// - Throws: `JSONError.invalidRequest` if any required field is missing or malformed.
internal struct JSONRequest: Decodable {

    // MARK: - Properties

    internal let jsonrpc: String
    internal var id: Int
    internal var method: String
    internal var params: JSONObject?

    // MARK: - Coding Keys

    private enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case method
        case params
    }

    // MARK: Initializers

    internal init(id: Int, method: String, params: JSONObject) {
        self.jsonrpc = jsonRpcVersion
        self.id = id
        self.method = method
        self.params = params
    }

    // MARK: - Decodable

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        guard jsonrpc == jsonRpcVersion else {
            throw JSONError.invalidRequest("jsonrpc field MUST be set to \"2.0\"")
        }

        // Handle ID as either an integer or a string representing an integer.
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = idInt
        } else if let idStr = try? container.decode(String.self, forKey: .id), let parsedId = Int(idStr) {
            self.id = parsedId
        } else {
            throw JSONError.invalidRequest("id field MUST exist and be a number or numeric string.")
        }

        guard let method = try container.decodeIfPresent(String.self, forKey: .method) else {
            throw JSONError.invalidRequest("method field MUST exist and be a string")
        }
        self.method = method

        if let params = try container.decodeIfPresent(JSONObject.self, forKey: .params) {
            self.params = params
        } else if container.contains(.params) {
            throw JSONError.invalidRequest("params field MUST be an array, object or null")
        } else {
            self.params = nil
        }
    }

    // MARK: - Utilities

    /// Serializes the JSON-RPC request into a dictionary representation.
    ///
    /// Primarily used for inspecting or forwarding the original request contents.
    ///
    /// - Returns: A dictionary conforming to JSON-RPC 2.0 format.
    internal func toDict() -> [String: JSONObject] {
        var dict: [String: JSONObject] = [
            "jsonrpc": .string(jsonRpcVersion),
            "id": .int(Int64(self.id)),
            "method": .string(self.method),
        ]

        params.map { dict["params"] = $0 }
        return dict
    }
}

/// Represents an outgoing JSON-RPC response object.
///
/// Encodes either a successful `result` or an `error`, but never both.
/// Conforms to JSON-RPC 2.0 response format and is returned to the client
/// after processing a `JSONRequest`.
internal struct JSONResponse: Encodable {

    // MARK: - Properties

    internal let jsonrpc: String
    internal var id: Int?
    internal var result: JSONObject?
    internal var error: JSONError?

    // MARK: - Initializers

    internal init(id: Int?, result: JSONObject) {
        self.jsonrpc = jsonRpcVersion
        self.id = id
        self.result = result
        self.error = nil
    }

    internal init(id: Int?, error: JSONError) {
        self.jsonrpc = jsonRpcVersion
        self.id = id
        self.result = nil
        self.error = error
    }
}

/// Represents errors that can occur during JSON-RPC parsing, dispatching, or execution.
///
/// Maps each error case to its corresponding JSON-RPC error code and message.
/// Optionally includes additional `data` for debugging or context.
/// Conforms to `Encodable` for automatic JSON serialization in responses.
///
/// - Note: `.hieroError` is a custom application-specific error beyond standard JSON-RPC types.
internal enum JSONError: Encodable, Error {

    // MARK: - Error Cases

    case hieroError(String, JSONObject? = nil)
    case invalidRequest(String, JSONObject? = nil)
    case methodNotFound(String, JSONObject? = nil)
    case invalidParams(String, JSONObject? = nil)
    case internalError(String, JSONObject? = nil)
    case parseError(String, JSONObject? = nil)

    // MARK: - Properties

    /// JSON-RPC error code corresponding to this case.
    internal var code: Int {
        switch self {
        case .hieroError: return -32001
        case .invalidRequest: return -32600
        case .methodNotFound: return -32601
        case .invalidParams: return -32602
        case .internalError: return -32603
        case .parseError: return -32700
        }
    }

    /// The descriptive message for the error.
    internal var message: String {
        switch self {
        case .hieroError(let msg, _),
            .invalidRequest(let msg, _),
            .methodNotFound(let msg, _),
            .invalidParams(let msg, _),
            .internalError(let msg, _),
            .parseError(let msg, _):
            return msg
        }
    }

    /// Optional error context or debug data.
    internal var data: JSONObject? {
        switch self {
        case .hieroError(_, let data),
            .invalidRequest(_, let data),
            .methodNotFound(_, let data),
            .invalidParams(_, let data),
            .internalError(_, let data),
            .parseError(_, let data):
            return data
        }
    }

    // MARK: - Encodable

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(data, forKey: .data)
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }
}

// MARK: - JSONObject

/// A recursive enum that represents any valid JSON value in a type-safe way.
///
/// Enables structured parsing and encoding of JSON values for use with strongly typed logic.
/// Handles JSON strings, numbers, booleans, arrays, and objects.
///
/// Commonly used to wrap arbitrary values passed to/from JSON-RPC endpoints or heterogeneous APIs.
internal enum JSONObject: Codable {

    // MARK: - JSON Value Cases

    case string(String)
    case int(Int64)
    case double(Double)
    case bool(Bool)
    case null
    case list([JSONObject])
    case dictionary([String: JSONObject])

    // MARK: - Accessors

    /// Returns the value as a `String` if this is a `.string`, else `nil`.
    internal var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    /// Returns the value as an `Int64` if this is an `.int`, else `nil`.
    internal var intValue: Int64? {
        if case .int(let value) = self {
            return value
        }
        return nil
    }

    /// Returns the value as a `Double` if this is a `.double`, else `nil`.
    internal var doubleValue: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }

    /// Returns the value as a `Bool` if this is a `.bool`, else `nil`.
    internal var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }

    /// Returns the value as a `[JSONObject]` if this is a `.list`, else `nil`.
    internal var listValue: [JSONObject]? {
        if case .list(let value) = self {
            return value
        }
        return nil
    }

    /// Returns the value as a `[String: JSONObject]` if this is a `.dictionary`, else `nil`.
    internal var dictValue: [String: JSONObject]? {
        if case .dictionary(let value) = self {
            return value
        }
        return nil
    }

    // MARK: - Codable

    internal init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([JSONObject].self) {
            self = .list(value)
        } else if let value = try? container.decode([String: JSONObject].self) {
            self = .dictionary(value)
        } else {
            throw JSONError.invalidParams("param type not recognized")
        }
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .list(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
}

// MARK: - JSON-RPC List Element Decoding

/// A type that can be constructed from a JSON-RPC parameter list element.
///
/// Conformers define how to decode themselves from a `JSONObject` dictionary
/// within an array parameter of a JSON-RPC request. This is typically used
/// for structured list elements such as transfers, allowances, or pending airdrops.
///
/// - Conforming types must supply:
///   - `elementName`: A human-readable label for use in error messages.
///   - An initializer that builds the type from a `[String: JSONObject]`
///     given the originating `JSONRPCMethod`.
internal protocol JSONRPCListElementDecodable {

    /// A descriptive name for this element type (e.g. `"transfer"`, `"airdrop"`),
    /// used in error messages when parsing fails.
    static var elementName: String { get }

    /// Creates an instance of the conforming type from a dictionary representation.
    ///
    /// - Parameters:
    ///   - params: The raw JSON object decoded into a `[String: JSONObject]`.
    ///   - method: The JSON-RPC method currently being parsed, included for error context.
    /// - Throws: `JSONError.invalidParams` if the dictionary is missing
    ///           required fields or contains invalid values.
    init(from params: [String: JSONObject], for method: JSONRPCMethod) throws
}

extension JSONRPCListElementDecodable {

    /// Returns a closure suitable for use with indexed JSON-RPC array parsing helpers.
    ///
    /// The closure validates that the element at the given index is a JSON object,
    /// then attempts to initialize the conforming type from it. If validation fails,
    /// the error message includes both the `method` name, the `elementName`, and the
    /// failing index for clear debugging context.
    ///
    /// - Parameters:
    ///   - method: The JSON-RPC method name, used in constructing error messages.
    /// - Returns: A closure that accepts a tuple `(Int, JSONObject)`, where `Int` is the
    ///   element’s index in the array, validates it, and decodes it as `Self`.
    /// - Throws: `JSONError.invalidParams` if the element at that index is not a dictionary
    ///           or cannot be parsed into a valid instance.
    internal static func jsonObjectDecoder(for method: JSONRPCMethod) -> (Int, JSONObject) throws -> Self {
        { index, json in
            guard let dict = json.dictValue else {
                throw JSONError.invalidParams(
                    "\(method.rawValue): \(Self.elementName)[\(index)] MUST be a JSON object.")
            }
            return try Self(from: dict, for: method)
        }
    }
}
