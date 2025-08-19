// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `claimToken` JSON-RPC method call.
///
/// This struct parses and validates inputs required to claim pending token airdrops.
/// It includes:
/// - `pendingAirdrops`: A required list of `PendingAirdrop` objects identifying which
///   airdrops are being claimed.
/// - `commonTransactionParams`: Optional shared transaction parameters for customizing
///   execution (e.g. fee payer, transaction memo).
///
/// Validation of required vs. optional fields is enforced during initialization.
/// Downstream logic may apply further defaults or business rules.
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
