// SPDX-License-Identifier: Apache-2.0

/// Represents a single transfer operation parsed from a JSON-RPC request.
///
/// Exactly one type of transfer must be provided per instance. Supported types:
/// - `hbar`: An HBAR transfer
/// - `token`: A fungible token transfer
/// - `nft`: A non-fungible token (NFT) transfer
///
/// Also includes an optional `approved` flag to indicate the transfer is allowanced.
///
/// This abstraction allows uniform parsing and validation of mixed transfer lists.
internal struct Transfer {

    internal var hbar: HbarTransfer? = nil
    internal var token: TokenTransfer? = nil
    internal var nft: NftTransfer? = nil
    internal var approved: Bool? = nil

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.hbar = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "hbar", from: params, for: method, using: HbarTransfer.init)
        self.token = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "token", from: params, for: method, using: TokenTransfer.init)
        self.nft = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "nft", from: params, for: method, using: NftTransfer.init)
        self.approved = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "approved", from: params, for: method)

        // Only one transfer type should be allowed.
        let nonNilCount = [self.hbar as Any?, self.token as Any?, self.nft as Any?].compactMap { $0 }
            .count
        if nonNilCount != 1 {
            throw JSONError.invalidParams("invalid parameters: only one type of transfer SHALL be provided.")
        }
    }

    /// Returns a closure that decodes a `JSONObject` into a `Transfer`, using the given method for error context.
    ///
    /// This is useful when parsing arrays of custom fee objects from JSON-RPC parameters,
    /// especially in conjunction with helper functions like `getOptionalCustomObjectListIfPresent`.
    ///
    /// - Parameters:
    ///   - method: The JSON-RPC method name, used for constructing informative error messages.
    /// - Returns: A closure that takes a `JSONObject`, validates its structure, and returns a parsed `Transfer`.
    /// - Throws: `JSONError.invalidParams` if the `JSONObject` is not a valid dictionary or cannot be parsed.
    static func jsonObjectDecoder(for method: JSONRPCMethod) -> (JSONObject) throws -> Transfer {
        return {
            guard let dict = $0.dictValue else {
                throw JSONError.invalidParams("\(method.rawValue): each transfer MUST be a JSON object.")
            }
            return try Transfer(from: dict, for: method)
        }
    }
}
