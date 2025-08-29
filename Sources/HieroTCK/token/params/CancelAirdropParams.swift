// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `cancelAirdrop` JSON-RPC method call.
///
/// This struct parses and validates inputs required to cancel pending token airdrops.
/// It includes:
/// - `pendingAirdrops`: A required list of `PendingAirdrop` objects identifying which
///   airdrops are being canceled.
/// - `commonTransactionParams`: Optional shared transaction parameters for customizing
///   execution (e.g. fee payer, transaction memo).
///
/// Validation of required vs. optional fields is enforced during initialization.
/// Downstream logic may apply further defaults or business rules.
internal struct CancelAirdropParams {

    internal var pendingAirdrops: [PendingAirdrop]
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .cancelAirdrop
        let params = try JSONRPCParser.getRequiredRequestParams(request: request)

        self.pendingAirdrops = try JSONRPCParser.getRequiredCustomObjectList(
            name: "pendingAirdrops",
            from: params,
            for: method,
            decoder: PendingAirdrop.jsonObjectDecoder(for: method))
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
