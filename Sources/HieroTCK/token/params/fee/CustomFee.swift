// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Represents a custom fee configuration parsed from a JSON-RPC request.
///
/// Supports exactly one of the following fee types per instance:
/// - `FixedFee`
/// - `FractionalFee`
/// - `RoyaltyFee`
///
/// Converts JSON input into typed `CustomFee` variants used for token creation or update operations.
internal struct CustomFee {

    internal var feeCollectorAccountId: String
    internal var feeCollectorsExempt: Bool
    internal var fixedFee: FixedFee? = nil
    internal var fractionalFee: FractionalFee? = nil
    internal var royaltyFee: RoyaltyFee? = nil

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.feeCollectorAccountId = try JSONRPCParser.getRequiredParameter(
            name: "feeCollectorAccountId", from: params, for: method)
        self.feeCollectorsExempt = try JSONRPCParser.getRequiredParameter(
            name: "feeCollectorsExempt", from: params, for: method)
        self.fixedFee = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "fixedFee", from: params, for: method, using: FixedFee.init)
        self.fractionalFee = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "fractionalFee", from: params, for: method, using: FractionalFee.init)
        self.royaltyFee = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "royaltyFee", from: params, for: method, using: RoyaltyFee.init)

        // Only one fee type should be allowed.
        let nonNilCount = [self.fixedFee as Any?, self.fractionalFee as Any?, self.royaltyFee as Any?].compactMap { $0 }
            .count
        if nonNilCount != 1 {
            throw JSONError.invalidParams("invalid parameters: only one type of fee SHALL be provided.")
        }
    }

    // MARK: - Helpers

    /// Converts this `CustomFee` type into a Hiero `AnyCustomFee` type.
    ///
    /// Ensures that exactly one fee type (`fixedFee`, `fractionalFee`, or `royaltyFee`) is provided.
    /// Constructs the appropriate fee variant with the common `feeCollectorAccountId` and `feeCollectorsExempt` values.
    ///
    /// - Parameters:
    ///   - method: The JSON-RPC method name, used for contextual error messages.
    /// - Returns: A strongly-typed `AnyCustomFee` (fixed, fractional, or royalty).
    /// - Throws: `JSONError.invalidParams` if more than one or no fee type is provided, or if parsing fails.
    internal func toHieroCustomFee(for method: JSONRPCMethod) throws -> AnyCustomFee {
        let feeCollectorAccountId = try AccountId.fromString(self.feeCollectorAccountId)
        let feeCollectorsExempt = self.feeCollectorsExempt

        // Ensure exactly one fee type is present.
        let nonNilFees = [self.fixedFee as Any?, self.fractionalFee as Any?, self.royaltyFee as Any?].compactMap { $0 }
        guard nonNilFees.count == 1 else {
            throw JSONError.invalidParams(
                "\(method): exactly one fee type (fixedFee, fractionalFee, or royaltyFee) SHALL be provided.")
        }

        if let fixed = self.fixedFee {
            return .fixed(
                try fixed.toHieroCustomFee(
                    feeCollectorAccountId: feeCollectorAccountId,
                    feeCollectorsExempt: feeCollectorsExempt,
                    for: method))
        } else if let fractional = self.fractionalFee {
            return .fractional(
                try fractional.toHieroCustomFee(
                    feeCollectorAccountId: feeCollectorAccountId,
                    feeCollectorsExempt: feeCollectorsExempt,
                    for: method))
        } else {
            // Safe to force unwrap since royalty is guaranteed to be non-nil at this point.
            return .royalty(
                try self.royaltyFee!.toHieroCustomFee(
                    feeCollectorAccountId: feeCollectorAccountId,
                    feeCollectorsExempt: feeCollectorsExempt,
                    for: method))
        }
    }

    /// Returns a closure that decodes a `JSONObject` into a `CustomFee`, using the given method for error context.
    ///
    /// This is useful when parsing arrays of custom fee objects from JSON-RPC parameters,
    /// especially in conjunction with helper functions like `getOptionalCustomObjectListIfPresent`.
    ///
    /// - Parameters:
    ///   - method: The JSON-RPC method name, used for constructing informative error messages.
    /// - Returns: A closure that takes a `JSONObject`, validates its structure, and returns a parsed `CustomFee`.
    /// - Throws: `JSONError.invalidParams` if the `JSONObject` is not a valid dictionary or cannot be parsed.
    static func jsonObjectDecoder(for method: JSONRPCMethod) -> (JSONObject) throws -> CustomFee {
        return {
            guard let dict = $0.dictValue else {
                throw JSONError.invalidParams("\(method.rawValue): each fee MUST be a JSON object.")
            }
            return try CustomFee(from: dict, for: method)
        }
    }
}
