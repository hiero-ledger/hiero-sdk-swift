// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Get information about the versions of protobuf and hedera.
///
public final class NetworkVersionInfoQuery: Query<NetworkVersionInfo> {
    /// Create a new `NetworkVersionInfoQuery`.
    public override init() {
    }

    internal override func toQueryProtobufWith(_ header: Proto_QueryHeader) -> Proto_Query {
        .with { proto in
            proto.networkGetVersionInfo = .with { proto in
                proto.header = header
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query) async throws -> Proto_Response {
        try await Proto_NetworkServiceAsyncClient(channel: channel).getVersionInfo(request)
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .networkGetVersionInfo(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `networkGetVersionInfo`")
        }

        return .fromProtobuf(proto)
    }
}
