// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `claimToken` JSON-RPC method call.
///
/// This struct captures the inputs required to claim one or more pending token airdrops.
/// It distinguishes between **required identifiers** and **optional modifiers**:
/// - `senderAccountId`: Required. The account ID of the original token sender.
/// - `receiverAccountId`: Required. The account ID of the intended recipient claiming the airdrop.
/// - `tokenId`: Required. The ID of the token being claimed.
/// - `serialNumbers`: Optional. Specific NFT serial numbers to claim (for non-fungible tokens).
/// - `commonTransactionParams`: Optional. Shared transaction parameters such as fee payer,
///   transaction memo, or custom fee settings.
///
/// Validation of required vs. optional fields occurs during initialization; parsing failures
/// throw `JSONError.invalidParams`. Additional business rules and defaulting may be applied
/// downstream when constructing and executing the transaction.
internal struct ClaimTokenParams {

    internal var senderAccountId: String
    internal var receiverAccountId: String
    internal var tokenId: String
    internal var serialNumbers: [String]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .claimToken
        let params = try JSONRPCParser.getRequiredRequestParams(request: request)

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
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
