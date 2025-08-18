// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `generateKey` JSON-RPC method call.
///
/// This structure supports recursive key generation strategies, including:
/// - Simple keys (e.g. "ED25519", "ECDSA_SECP256K1")
/// - Derived keys using `fromKey`
/// - Threshold keys with `threshold` and nested `keys`
///
/// This is designed to map directly from JSON-RPC input and enforce validation
/// on required and optional parameters through the parsing logic.
internal struct GenerateKeyParams {

    internal var type: String
    internal var fromKey: String? = nil
    internal var threshold: UInt32? = nil
    internal var keys: [GenerateKeyParams]? = nil

    /// Initializes from a full `JSONRequest`.
    ///
    /// - Parameters:
    ///   - request: The JSON-RPC request parameters.
    /// - Throws: `JSONError.invalidParams` if required fields are missing or malformed.
    internal init(request: JSONRequest) throws {
        try self.init(params: JSONRPCParser.getRequiredRequestParams(request: request))
    }

    /// Initializes from a `[String: JSONObject]` parameter map.
    ///
    /// - Parameters:
    ///   - params: The JSON-RPC parameters for this key.
    /// - Throws: `JSONError.invalidParams` for invalid or missing fields.
    private init(params: [String: JSONObject]) throws {
        let method: JSONRPCMethod = .generateKey

        self.type = try JSONRPCParser.getRequiredParameter(
            name: "type", from: params, for: method)
        self.fromKey = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "fromKey", from: params, for: method)
        self.threshold = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "threshold", from: params, for: method)
        self.keys = try JSONRPCParser.getOptionalCustomObjectListIfPresent(
            name: "keys", from: params, for: method
        ) {
            try GenerateKeyParams(params: JSONRPCParser.getJson(name: "key in keys list", from: $0, for: method))
        }
    }
}
