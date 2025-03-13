// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'deleteToken' JSON-RPC method call.
internal struct DeleteTokenParams {

    internal var tokenId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.tokenId = try getOptionalJsonParameter("tokenId", params, JSONRPCMethod.deleteToken)
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.deleteToken),
                JSONRPCMethod.deleteToken)
        }
    }
}
