// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'associateToken' JSON-RPC method call.
internal struct AssociateTokenParams {

    internal var accountId: String? = nil
    internal var tokenIds: [String]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.accountId = try getOptionalJsonParameter("accountId", params, JSONRPCMethod.associateToken)
            self.tokenIds = try
                (getOptionalJsonParameter("tokenIds", params, JSONRPCMethod.associateToken) as [JSONObject]?)?.map {
                    try getJson($0, "token ID in tokenIds list", JSONRPCMethod.associateToken) as String
                }
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.associateToken),
                JSONRPCMethod.associateToken)
        }
    }
}
