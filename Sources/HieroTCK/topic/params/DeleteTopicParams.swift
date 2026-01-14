// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `deleteTopic` JSON-RPC method call.
internal struct DeleteTopicParams {

    internal var topicId: String?
    internal var commonTransactionParams: CommonTransactionParams?

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .deleteTopic
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.topicId = try JSONRPCParser.getOptionalParameterIfPresent(name: "topicId", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
