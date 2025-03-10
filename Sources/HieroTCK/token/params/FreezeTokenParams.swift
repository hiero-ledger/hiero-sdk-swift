// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'freezeToken' JSON-RPC method call.
internal struct FreezeTokenParams {

    internal var tokenId: String? = nil
    internal var accountId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.tokenId = try getOptionalJsonParameter("tokenId", params, JSONRPCMethod.freezeToken)
            self.accountId = try getOptionalJsonParameter("accountId", params, JSONRPCMethod.freezeToken)
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.freezeToken),
                JSONRPCMethod.freezeToken)
        }
    }
}
