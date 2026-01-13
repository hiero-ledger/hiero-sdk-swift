// SPDX-License-Identifier: Apache-2.0

/// Parameters for the `getAccountInfo` JSON-RPC method.
internal struct GetAccountInfoParams {
    
    internal var accountId: String? = nil

    internal init(request: JSONRequest) throws {
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else {
            return
        }

        self.accountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "accountId",
            from: params,
            for: .getAccountInfo
        )
    }
}
