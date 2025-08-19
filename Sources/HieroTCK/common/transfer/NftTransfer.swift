// SPDX-License-Identifier: Apache-2.0

import Hiero

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
            name: "senderAccountId",
            from: params,
            for: method)
        self.receiverAccountId = try JSONRPCParser.getRequiredParameter(
            name: "receiverAccountId",
            from: params,
            for: method)
        self.tokenId = try JSONRPCParser.getRequiredParameter(
            name: "tokenId",
            from: params,
            for: method)
        self.serialNumber = try JSONRPCParser.getRequiredParameter(
            name: "serialNumber",
            from: params,
            for: method)
    }

    /// Applies this NFT transfer to the given token transfer transaction.
    ///
    /// This method resolves the `senderAccountId`, `receiverAccountId`, `tokenId`, and `serialNumber`
    /// fields into SDK-level types and attaches the corresponding NFT transfer to the provided
    /// `AbstractTokenTransferTransaction`. The `approved` flag determines whether the transfer
    /// should be recorded as an approved allowance transfer.
    ///
    /// - Parameters:
    ///   - tx: The NFT transfer transaction to modify.
    ///   - approved: Whether the transfer should be marked as approved via allowance.
    ///   - method: The JSON-RPC method name, used for error reporting during parsing.
    /// - Throws: `JSONError.invalidParams` if any parameter is invalid or cannot be parsed.
    internal func applyToTransaction<T: AbstractTokenTransferTransaction>(
        _ tx: inout T,
        approved: Bool,
        for method: JSONRPCMethod
    ) throws {
        let sender = try AccountId.fromString(self.senderAccountId)
        let receiver = try AccountId.fromString(self.receiverAccountId)
        let nftId = NftId(
            tokenId: try TokenId.fromString(self.tokenId),
            serial: try CommonParamsParser.getSerialNumber(from: self.serialNumber, for: method))
        _ = approved ? tx.approvedNftTransfer(nftId, sender, receiver) : tx.nftTransfer(nftId, sender, receiver)
    }
}
