// SPDX-License-Identifier: Apache-2.0

/// Represents a single transfer operation parsed from a JSON-RPC request.
///
/// Exactly one transfer type must be provided per instance. Supported types:
/// - `hbar`: An HBAR transfer.
/// - `token`: A fungible token transfer.
/// - `nft`: A non-fungible token (NFT) transfer.
///
/// The optional `approved` flag marks the transfer as pre-approved via allowance.
/// This abstraction enables uniform parsing/validation of mixed transfer lists.
internal struct Transfer: JSONRPCListElementDecodable {
    internal static let elementName = "transfer"

    internal var hbar: HbarTransfer? = nil
    internal var token: TokenTransfer? = nil
    internal var nft: NftTransfer? = nil
    internal var approved: Bool? = nil

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.hbar = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "hbar",
            from: params,
            for: method,
            using: HbarTransfer.init)
        self.token = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "token",
            from: params,
            for: method,
            using: TokenTransfer.init)
        self.nft = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "nft",
            from: params,
            for: method,
            using: NftTransfer.init)
        self.approved = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "approved",
            from: params,
            for: method)

        // Only one transfer type should be allowed.
        let nonNilCount = [self.hbar as Any?, self.token as Any?, self.nft as Any?].compactMap { $0 }
            .count
        if nonNilCount != 1 {
            throw JSONError.invalidParams("invalid parameters: only one type of transfer SHALL be provided.")
        }
    }
}
