// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `deleteAccount` JSON-RPC method call.
///
/// This struct extracts and stores the optional fields required to perform a `deleteAccount`
/// operation, including the account to delete, the account to transfer remaining balance to,
/// and any shared transaction configuration.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct DeleteAccountParams {

    internal var deleteAccountId: String? = nil
    internal var transferAccountId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .deleteAccount
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.deleteAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "deleteAccountId",
            from: params,
            for: method)
        self.transferAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "transferAccountId",
            from: params,
            for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
