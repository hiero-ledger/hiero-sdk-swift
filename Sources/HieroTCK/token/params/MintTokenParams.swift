// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `mintToken` JSON-RPC method call.
///
/// This struct encapsulates optional parameters for minting new tokens. It supports
/// specifying an amount (for fungible tokens), metadata entries (for NFTs),
/// and common transaction-level parameters such as fees, memo, or signing info.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct MintTokenParams {

    internal var tokenId: String? = nil
    internal var amount: String? = nil
    internal var metadata: [String]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .mintToken
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalParameterIfPresent(name: "tokenId", from: params, for: method)
        self.amount = try JSONRPCParser.getOptionalParameterIfPresent(name: "amount", from: params, for: method)
        self.metadata = try JSONRPCParser.getOptionalPrimitiveListIfPresent(name: "metadata", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
