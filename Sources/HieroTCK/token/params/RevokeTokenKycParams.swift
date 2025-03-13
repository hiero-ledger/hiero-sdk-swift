// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'revokeTokenKyc' JSON-RPC method call.
internal struct RevokeTokenKycParams {

    internal var tokenId: String? = nil
    internal var accountId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.tokenId = try getOptionalJsonParameter("tokenId", params, JSONRPCMethod.revokeTokenKyc)
            self.accountId = try getOptionalJsonParameter("accountId", params, JSONRPCMethod.revokeTokenKyc)
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.revokeTokenKyc),
                JSONRPCMethod.revokeTokenKyc)
        }
    }
}
