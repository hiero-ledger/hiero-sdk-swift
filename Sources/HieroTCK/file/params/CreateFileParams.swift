// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `createFile` JSON-RPC method call.
///
/// This struct captures the optional inputs needed to create a new file on the network.
/// It includes support for specifying controlling keys, initial file contents, expiration time,
/// memo text, and common transaction parameters such as fee settings or signing options.
///
/// - Note: All fields are optional; validation, defaulting, and enforcement of constraints
///         (such as expiration handling or key validation) are deferred to downstream logic.
internal struct CreateFileParams {

    internal var keys: [String]? = nil
    internal var contents: String? = nil
    internal var expirationTime: String? = nil
    internal var memo: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .createFile
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.keys = try JSONRPCParser.getOptionalPrimitiveListIfPresent(name: "keys", from: params, for: method)
        self.contents = try JSONRPCParser.getOptionalParameterIfPresent(name: "contents", from: params, for: method)
        self.expirationTime = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "expirationTime",
            from: params,
            for: method)
        self.memo = try JSONRPCParser.getOptionalParameterIfPresent(name: "memo", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
