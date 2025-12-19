// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Get the contents of a file.
public final class FileContentsQuery: Query<FileContentsResponse> {
    /// Create a new `FileContentsQuery` ready for configuration.
    public override init() {}

    /// The file ID for which contents are requested.
    public var fileId: FileId?

    /// Sets the file ID for which contents are requested.
    @discardableResult
    public func fileId(_ fileId: FileId) -> Self {
        self.fileId = fileId

        return self
    }

    internal override func toQueryProtobufWith(_ header: Proto_QueryHeader) -> Proto_Query {
        .with { proto in
            proto.fileGetContents = .with { proto in
                proto.header = header
                fileId?.toProtobufInto(&proto.fileID)
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query, _ deadline: TimeInterval) async throws -> Proto_Response {
        try await Proto_FileServiceAsyncClient(channel: channel).getFileContent(request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .fileGetContents(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `fileGetContents`")
        }

        return .fromProtobuf(proto.fileContents)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try fileId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }
}
