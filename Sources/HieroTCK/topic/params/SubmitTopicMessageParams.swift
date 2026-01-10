// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `submitTopicMessage` JSON-RPC method call.
internal struct SubmitTopicMessageParams {

    internal var topicId: String? = nil
    internal var message: String? = nil
    internal var maxChunks: Int64? = nil
    internal var chunkSize: Int64? = nil
    internal var customFeeLimits: [CustomFeeLimit]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .submitTopicMessage
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.topicId = try JSONRPCParser.getOptionalParameterIfPresent(name: "topicId", from: params, for: method)
        self.message = try JSONRPCParser.getOptionalParameterIfPresent(name: "message", from: params, for: method)
        self.maxChunks = try JSONRPCParser.getOptionalParameterIfPresent(name: "maxChunks", from: params, for: method)
        self.chunkSize = try JSONRPCParser.getOptionalParameterIfPresent(name: "chunkSize", from: params, for: method)
        self.customFeeLimits = try JSONRPCParser.getOptionalCustomObjectListIfPresent(
            name: "customFeeLimits",
            from: params,
            for: method,
            decoder: CustomFeeLimit.jsonObjectDecoder(for: method))
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
