// SPDX-License-Identifier: Apache-2.0

/// Represents an NFT (non-fungible token) transfer parsed from a JSON-RPC request.
///
/// This struct is used to decode and validate a single NFT transfer entry. It includes:
/// - `senderAccountId`: The ID of the account transferring ownership of the NFT.
/// - `receiverAccountId`: The ID of the account receiving the NFT.
/// - `tokenId`: The ID of the NFT collection.
/// - `serialNumber`: The serial number of the specific NFT being transferred.
internal struct NftTransfer {

    internal var senderAccountId: String
    internal var receiverAccountId: String
    internal var tokenId: String
    internal var serialNumber: String

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.senderAccountId = try JSONRPCParser.getRequiredParameter(
            name: "senderAccountId", from: params, for: method)
        self.receiverAccountId = try JSONRPCParser.getRequiredParameter(
            name: "receiverAccountId", from: params, for: method)
        self.tokenId = try JSONRPCParser.getRequiredParameter(
            name: "tokenId", from: params, for: method)
        self.serialNumber = try JSONRPCParser.getRequiredParameter(
            name: "serialNumber", from: params, for: method)
    }
}
