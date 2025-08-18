// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Represents a parsed remove allowance object from a JSON-RPC request.
///
/// This struct encapsulates an NFT allowance to be removed granted by an `ownerAccountId`,
/// for the NFTs of the `tokenId` token class and with the `serialNumbers`.
///
/// The initializer validates that all fields are present.
internal struct RemoveAllowance {

    internal var ownerAccountId: String
    internal var tokenId: String
    internal var serialNumbers: [String]

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.ownerAccountId = try JSONRPCParser.getRequiredParameter(
            name: "ownerAccountId", from: params, for: method)
        self.tokenId = try JSONRPCParser.getRequiredParameter(
            name: "tokenId", from: params, for: method)
        self.serialNumbers = try JSONRPCParser.getRequiredPrimitiveList(
            name: "serialNumbers", from: params, for: method)
    }

    /// Returns a closure that decodes a `JSONObject` into a `RemoveAllowance`, using the given method for error context.
    ///
    /// This is useful when parsing arrays of custom fee objects from JSON-RPC parameters,
    /// especially in conjunction with helper functions like `getRequiredCustomObjectListIfPresent`.
    ///
    /// - Parameters:
    ///   - method: The JSON-RPC method name, used for constructing informative error messages.
    /// - Returns: A closure that takes a `JSONObject`, validates its structure, and returns a parsed `RemoveAllowance`.
    /// - Throws: `JSONError.invalidParams` if the `JSONObject` is not a valid dictionary or cannot be parsed.
    static func jsonObjectDecoder(for method: JSONRPCMethod) -> (JSONObject) throws -> RemoveAllowance {
        return {
            guard let dict = $0.dictValue else {
                throw JSONError.invalidParams("\(method.rawValue): each allowance MUST be a JSON object.")
            }
            return try RemoveAllowance(from: dict, for: method)
        }
    }
}
