// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'deleteAccount' JSON-RPC method call.
internal struct DeleteAccountParams {

    internal var deleteAccountId: String? = nil
    internal var transferAccountId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.deleteAccountId = try getOptionalJsonParameter("deleteAccountId", params, JSONRPCMethod.deleteAccount)
            self.transferAccountId = try getOptionalJsonParameter(
                "transferAccountId", params, JSONRPCMethod.deleteAccount)
            self.commonTransactionParams = try CommonTransactionParams(
                getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.deleteAccount),
                JSONRPCMethod.deleteAccount)
        }
    }
}
