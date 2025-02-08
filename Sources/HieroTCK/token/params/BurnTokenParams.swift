// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'burnToken' JSON-RPC method call.
internal struct BurnTokenParams {

    internal var tokenId: String? = nil
    internal var amount: String? = nil
    internal var serialNumbers: [String]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.tokenId = try getOptionalJsonParameter("tokenId", params, JSONRPCMethod.burnToken)
            self.amount = try getOptionalJsonParameter("amount", params, JSONRPCMethod.burnToken)
            self.serialNumbers = try
                (getOptionalJsonParameter("serialNumbers", params, JSONRPCMethod.burnToken) as [JSONObject]?)?.map {
                    try getJson($0, "serial number in serialNumbers list", JSONRPCMethod.burnToken)
                }
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.burnToken),
                JSONRPCMethod.burnToken)
        }
    }
}
