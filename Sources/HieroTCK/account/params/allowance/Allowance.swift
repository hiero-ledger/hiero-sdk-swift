// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Represents a parsed allowance object from a JSON-RPC request.
///
/// This struct encapsulates a single allowance granted by an `ownerAccountId` to a `spenderAccountId`,
/// and supports exactly one of the following types:
/// - `HbarAllowance`
/// - `TokenAllowance`
/// - `NftAllowance`
///
/// The initializer validates that:
/// - The required fields `ownerAccountId` and `spenderAccountId` are present.
/// - At most one of `hbar`, `token`, or `nft` is provided. If none or more than one are present, it throws an error.
///
/// Used for decoding and validating user-defined allowance declarations in JSON-RPC requests.
internal struct Allowance {

    internal var ownerAccountId: String
    internal var spenderAccountId: String
    internal var hbar: HbarAllowance? = nil
    internal var token: TokenAllowance? = nil
    internal var nft: NftAllowance? = nil

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.ownerAccountId = try JSONRPCParser.getRequiredParameter(
            name: "ownerAccountId", from: params, for: method)
        self.spenderAccountId = try JSONRPCParser.getRequiredParameter(
            name: "spenderAccountId", from: params, for: method)
        self.hbar = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "hbar", from: params, for: method, using: HbarAllowance.init)
        self.token = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "token", from: params, for: method, using: TokenAllowance.init)
        self.nft = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "nft", from: params, for: method, using: NftAllowance.init)

        // Only one allowance type should be allowed.
        let nonNilCount = [self.hbar as Any?, self.token as Any?, self.nft as Any?].compactMap { $0 }.count
        if nonNilCount != 1 {
            throw JSONError.invalidParams("invalid parameters: only one type of allowance SHALL be provided.")
        }
    }

    /// Returns a closure that decodes a `JSONObject` into an `Allowance`, using the given method for error context.
    ///
    /// This is useful when parsing arrays of custom fee objects from JSON-RPC parameters,
    /// especially in conjunction with helper functions like `getOptionalCustomObjectListIfPresent`.
    ///
    /// - Parameters:
    ///   - method: The JSON-RPC method name, used for constructing informative error messages.
    /// - Returns: A closure that takes a `JSONObject`, validates its structure, and returns a parsed `Allowance`.
    /// - Throws: `JSONError.invalidParams` if the `JSONObject` is not a valid dictionary or cannot be parsed.
    static func jsonObjectDecoder(for method: JSONRPCMethod) -> (JSONObject) throws -> Allowance {
        return {
            guard let dict = $0.dictValue else {
                throw JSONError.invalidParams("\(method.rawValue): each allowance MUST be a JSON object.")
            }
            return try Allowance(from: dict, for: method)
        }
    }
}
