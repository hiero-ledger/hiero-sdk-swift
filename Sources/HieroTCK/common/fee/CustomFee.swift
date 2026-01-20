// SPDX-License-Identifier: Apache-2.0

/// Represents a custom fee configuration parsed from a JSON-RPC request.
///
/// Supports exactly one of the following fee types per instance:
/// - `FixedFee`
/// - `FractionalFee`
/// - `RoyaltyFee`
///
/// Converts JSON input into typed `CustomFee` variants used for token creation or update operations.
internal struct CustomFee: JSONRPCListElementDecodable {
    internal static let elementName = "custom fee"

    internal var feeCollectorAccountId: String
    internal var feeCollectorsExempt: Bool
    internal var fixedFee: FixedFee? = nil
    internal var fractionalFee: FractionalFee? = nil
    internal var royaltyFee: RoyaltyFee? = nil

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.feeCollectorAccountId = try JSONRPCParser.getRequiredParameter(
            name: "feeCollectorAccountId",
            from: params,
            for: method)
        self.feeCollectorsExempt = try JSONRPCParser.getRequiredParameter(
            name: "feeCollectorsExempt",
            from: params,
            for: method)
        self.fixedFee = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "fixedFee",
            from: params,
            for: method,
            using: FixedFee.init)
        self.fractionalFee = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "fractionalFee",
            from: params,
            for: method,
            using: FractionalFee.init)
        self.royaltyFee = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "royaltyFee",
            from: params,
            for: method,
            using: RoyaltyFee.init)

        // Only one fee type should be allowed.
        let nonNilCount = [self.fixedFee as Any?, self.fractionalFee as Any?, self.royaltyFee as Any?].compactMap { $0 }
            .count
        if nonNilCount != 1 {
            throw JSONError.invalidParams("invalid parameters: only one type of fee SHALL be provided.")
        }
    }
}
