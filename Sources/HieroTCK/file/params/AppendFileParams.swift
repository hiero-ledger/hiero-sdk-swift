// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `createFile` JSON-RPC method call.
///
/// This struct captures the optional inputs needed to create a new file on the network.
/// It includes support for specifying controlling keys, initial file contents, expiration time,
/// memo text, and common transaction parameters such as fee settings or signing options.
///
/// - Note: All fields are optional; validation, defaulting, and enforcement of constraints
///         (such as expiration handling or key validation) are deferred to downstream logic.
internal struct AppendFileParams {

    internal var fileId: String? = nil
    internal var contents: String? = nil
    internal var maxChunks: Int? = nil
    internal var chunkSize: Int? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .appendFile
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.fileId = try JSONRPCParser.getOptionalParameterIfPresent(name: "fileId", from: params, for: method)
        self.contents = try JSONRPCParser.getOptionalParameterIfPresent(name: "contents", from: params, for: method)
        self.maxChunks = try JSONRPCParser.getOptionalParameterIfPresent(name: "maxChunks", from: params, for: method)
        self.chunkSize = try JSONRPCParser.getOptionalParameterIfPresent(name: "chunkSize", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
