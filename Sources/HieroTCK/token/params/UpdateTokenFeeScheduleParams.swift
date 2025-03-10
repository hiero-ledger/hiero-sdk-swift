// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'updateTokenFeeSchedule' JSON-RPC method call.
internal struct UpdateTokenFeeScheduleParams {

    internal var tokenId: String? = nil
    internal var customFees: [CustomFee]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.tokenId = try getOptionalJsonParameter("tokenId", params, JSONRPCMethod.updateTokenFeeSchedule)
            self.customFees = try
                (getOptionalJsonParameter("customFees", params, JSONRPCMethod.updateTokenFeeSchedule)
                as [JSONObject]?)?.map {
                    try CustomFee(
                        getJson($0, "fee in custom fees list", JSONRPCMethod.updateTokenFeeSchedule),
                        JSONRPCMethod.updateTokenFeeSchedule)
                }
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter(
                    "commonTransactionParams", params, JSONRPCMethod.updateTokenFeeSchedule),
                JSONRPCMethod.updateTokenFeeSchedule)
        }
    }
}
