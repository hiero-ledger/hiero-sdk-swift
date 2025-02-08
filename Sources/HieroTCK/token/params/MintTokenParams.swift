// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'mintToken' JSON-RPC method call.
internal struct MintTokenParams {

    internal var tokenId: String? = nil
    internal var amount: String? = nil
    internal var metadata: [String]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.tokenId = try getOptionalJsonParameter("tokenId", params, JSONRPCMethod.mintToken)
            self.amount = try getOptionalJsonParameter("amount", params, JSONRPCMethod.mintToken)
            self.metadata = try
                (getOptionalJsonParameter("metadata", params, JSONRPCMethod.mintToken) as [JSONObject]?)?.map {
                    try getJson($0, "metadata in metadata list", JSONRPCMethod.mintToken)
                }
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.mintToken),
                JSONRPCMethod.mintToken)
        }
    }
}
