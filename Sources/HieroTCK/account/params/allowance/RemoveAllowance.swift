// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Represents a parsed remove allowance object from a JSON-RPC request.
///
/// This struct encapsulates an NFT allowance to be removed granted by an `ownerAccountId`,
/// for the NFTs of the `tokenId` token class and with the `serialNumbers`.
///
/// The initializer validates that all fields are present.
internal struct RemoveAllowance: JSONRPCListElementDecodable {
    internal static let elementName = "allowance"

    internal var ownerAccountId: String
    internal var tokenId: String
    internal var serialNumbers: [String]

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.ownerAccountId = try JSONRPCParser.getRequiredParameter(
            name: "ownerAccountId",
            from: params,
            for: method)
        self.tokenId = try JSONRPCParser.getRequiredParameter(
            name: "tokenId",
            from: params,
            for: method)
        self.serialNumbers = try JSONRPCParser.getRequiredPrimitiveList(
            name: "serialNumbers",
            from: params,
            for: method)
    }
}
