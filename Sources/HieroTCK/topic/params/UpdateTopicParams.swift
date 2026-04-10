// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for an `updateTopic` JSON-RPC method call.
///
/// This struct encapsulates all supported topic update parameters,
/// including memo, keys, auto-renew settings, expiration, and fee configuration.
internal struct UpdateTopicParams {

    internal var topicId: String?
    internal var memo: String?
    internal var adminKey: String?
    internal var submitKey: String?
    internal var autoRenewPeriod: String?
    internal var autoRenewAccountId: String?
    internal var expirationTime: String?
    internal var feeScheduleKey: String?
    internal var feeExemptKeys: [String]?
    internal var customFees: [CustomFee]?
    internal var commonTransactionParams: CommonTransactionParams?

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .updateTopic
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.topicId = try JSONRPCParser.getOptionalParameterIfPresent(name: "topicId", from: params, for: method)
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
        self.expirationTime = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "expirationTime",
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
