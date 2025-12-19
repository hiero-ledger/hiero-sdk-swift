// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Get all the information about a file.
public final class FileInfoQuery: Query<FileInfo> {
    /// Create a new `FileInfoQuery`.
    public init(
        fileId: FileId? = nil
    ) {
        self.fileId = fileId
    }

    /// The file ID for which information is requested.
    public var fileId: FileId?

    /// Sets the file ID for which information is requested.
    @discardableResult
    public func fileId(_ fileId: FileId) -> Self {
        self.fileId = fileId

        return self
    }

    internal override func toQueryProtobufWith(_ header: Proto_QueryHeader) -> Proto_Query {
        .with { proto in
            proto.fileGetInfo = .with { proto in
                proto.header = header
                fileId?.toProtobufInto(&proto.fileID)
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query, _ deadline: TimeInterval) async throws -> Proto_Response {
        try await Proto_FileServiceAsyncClient(channel: channel).getFileInfo(request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .fileGetInfo(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `fileGetInfo`")
        }

        return try .fromProtobuf(proto.fileInfo)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try fileId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }
}
