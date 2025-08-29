// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `deleteFile` JSON-RPC method call.
///
/// This struct captures the optional inputs required to delete a file on the network.
/// It supports specifying the target `fileId` and common transaction parameters
/// (such as fee settings or signing options).
///
/// - Note: All fields are optional; validation, defaulting, and enforcement of
///         requirements (such as ensuring a valid `fileId`) are deferred to downstream logic.
internal struct DeleteFileParams {

    internal var fileId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .deleteFile
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.fileId = try JSONRPCParser.getOptionalParameterIfPresent(name: "fileId", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
