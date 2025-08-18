// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for an `updateTokenFeeSchedule` JSON-RPC method call.
///
/// This struct encapsulates the optional parameters required to update the fee schedule for a token,
/// including the `tokenId`, a list of `customFees`, and common transaction metadata.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct UpdateTokenFeeScheduleParams {

    internal var tokenId: String? = nil
    internal var customFees: [CustomFee]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .updateTokenFeeSchedule
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalParameterIfPresent(name: "tokenId", from: params, for: method)
        self.customFees = try JSONRPCParser.getOptionalCustomObjectListIfPresent(
            name: "customFees", from: params, for: method, decoder: CustomFee.jsonObjectDecoder(for: method))
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams", from: params, for: method, using: CommonTransactionParams.init)
    }
}
