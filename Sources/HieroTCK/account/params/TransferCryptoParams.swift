// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for an `transferCrypto` JSON-RPC method call.
///
/// This struct parses and holds a list of `Transfer` objects to be transferred,
/// along with optional `CommonTransactionParams` for the transaction.
internal struct TransferCryptoParams {

    internal var transfers: [Transfer]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .transferCrypto
        let params = try JSONRPCParser.getRequiredRequestParams(request: request)

        self.transfers = try JSONRPCParser.getOptionalCustomObjectListIfPresent(
            name: "transfers",
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
