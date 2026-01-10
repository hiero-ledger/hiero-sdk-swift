// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `createTopic` JSON-RPC method call.
///
/// This struct encapsulates all supported topic creation parameters,
/// including memo, keys, auto-renew settings, and fee configuration.
internal struct CreateTopicParams {

    internal var memo: String? = nil
    internal var adminKey: String? = nil
    internal var submitKey: String? = nil
    internal var autoRenewPeriod: String? = nil
    internal var autoRenewAccountId: String? = nil
    internal var feeScheduleKey: String? = nil
    internal var feeExemptKeys: [String]? = nil
    internal var customFees: [CustomFee]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .createTopic
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.memo = try JSONRPCParser.getOptionalParameterIfPresent(name: "memo", from: params, for: method)
        self.adminKey = try JSONRPCParser.getOptionalParameterIfPresent(name: "adminKey", from: params, for: method)
        self.submitKey = try JSONRPCParser.getOptionalParameterIfPresent(name: "submitKey", from: params, for: method)
        self.autoRenewPeriod = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "autoRenewPeriod",
            from: params,
            for: method)
        self.autoRenewAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "autoRenewAccountId",
            from: params,
            for: method)
        self.feeScheduleKey = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "feeScheduleKey",
            from: params,
            for: method)
        self.feeExemptKeys = try JSONRPCParser.getOptionalPrimitiveListIfPresent(
            name: "feeExemptKeys",
            from: params,
            for: method)
        self.customFees = try JSONRPCParser.getOptionalCustomObjectListIfPresent(
            name: "customFees",
            from: params,
            for: method,
            decoder: CustomFee.jsonObjectDecoder(for: method))
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
