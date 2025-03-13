// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'unfreezeToken' JSON-RPC method call.
internal struct UnfreezeTokenParams {

    internal var tokenId: String? = nil
    internal var accountId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.tokenId = try getOptionalJsonParameter("tokenId", params, JSONRPCMethod.unfreezeToken)
            self.accountId = try getOptionalJsonParameter("accountId", params, JSONRPCMethod.unfreezeToken)
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.unfreezeToken),
                JSONRPCMethod.unfreezeToken)
        }
    }
}
