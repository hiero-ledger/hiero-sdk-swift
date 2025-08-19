// SPDX-License-Identifier: Apache-2.0

/// Represents a pending token airdrop parsed from a JSON-RPC request.
///
/// This struct is used to decode and validate a single pending airdrop entry. It includes:
/// - `senderAccountId`: The ID of the account initiating the airdrop.
/// - `receiverAccountId`: The ID of the account designated to receive the airdrop.
/// - `tokenId`: The ID of the token being airdropped (fungible or NFT).
/// - `serialNumbers`: An optional list of NFT serial numbers, present only when the airdrop
///   involves non-fungible tokens.
internal struct PendingAirdrop: JSONRPCListElementDecodable {
    internal static let elementName = "airdrop"

    internal var senderAccountId: String
    internal var receiverAccountId: String
    internal var tokenId: String
    internal var serialNumbers: [String]?

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.senderAccountId = try JSONRPCParser.getRequiredParameter(
            name: "senderAccountId",
            from: params,
            for: method)
        self.receiverAccountId = try JSONRPCParser.getRequiredParameter(
            name: "receiverAccountId",
            from: params,
            for: method)
        self.tokenId = try JSONRPCParser.getRequiredParameter(name: "tokenId", from: params, for: method)
        self.serialNumbers = try JSONRPCParser.getOptionalPrimitiveListIfPresent(
            name: "serialNumbers",
            from: params,
            for: method)
    }
}
