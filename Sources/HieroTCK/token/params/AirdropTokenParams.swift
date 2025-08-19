// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for an `airdropToken` JSON-RPC method call.
///
/// This struct captures optional inputs for performing a token airdrop transaction.
/// It may include a list of token transfers and common transaction parameters to
/// customize execution. If no parameters are provided, defaults or validation may
/// occur downstream.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct AirdropTokenParams {

    internal var tokenTransfers: [Transfer]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .airdropToken
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.tokenTransfers = try JSONRPCParser.getOptionalCustomObjectListIfPresent(
            name: "tokenTransfers",
            from: params,
            for: method,
            decoder: Transfer.jsonObjectDecoder(for: method))
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
