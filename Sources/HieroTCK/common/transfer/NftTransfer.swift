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

    internal init(from params: [String: JSONObject], for funcName: JSONRPCMethod) throws {
        self.senderAccountId = try JSONRPCParser.getRequiredJsonParameter(
            name: "senderAccountId", from: params, for: funcName)
        self.receiverAccountId = try JSONRPCParser.getRequiredJsonParameter(
            name: "receiverAccountId", from: params, for: funcName)
        self.tokenId = try JSONRPCParser.getRequiredJsonParameter(
            name: "tokenId", from: params, for: funcName)
        self.serialNumber = try JSONRPCParser.getRequiredJsonParameter(
            name: "serialNumber", from: params, for: funcName)
    }
}
