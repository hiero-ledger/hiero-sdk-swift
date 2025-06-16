// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Gets info on an NFT for a given TokenID and serial number.
public final class TokenNftInfoQuery: Query<TokenNftInfo> {
    /// Create a new `TokenNftInfoQuery`.
    public init(
        nftId: NftId? = nil
    ) {
        self.nftId = nftId
    }

    /// The nft ID for which information is requested.
    public var nftId: NftId?

    /// Sets the nft ID for which information is requested.
    @discardableResult
    public func nftId(_ nftId: NftId) -> Self {
        self.nftId = nftId

        return self
    }

    internal override func toQueryProtobufWith(_ header: Proto_QueryHeader) -> Proto_Query {
        .with { proto in
            proto.tokenGetNftInfo = .with { proto in
                proto.header = header
                nftId?.toProtobufInto(&proto.nftID)
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query) async throws -> Proto_Response {
        try await Proto_TokenServiceAsyncClient(channel: channel).getTokenNftInfo(
            request, callOptions: applyGrpcHeader())
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .tokenGetNftInfo(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `tokenGetNftInfo`")
        }

        return try .fromProtobuf(proto.nft)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try nftId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }
}
