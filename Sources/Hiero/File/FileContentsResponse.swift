// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Response from `FileContentsQuery`.
public struct FileContentsResponse {
    /// The file ID of the file whose contents are being returned.
    public let fileId: FileId

    /// The bytes contained in the file.
    public let contents: Data
}

extension FileContentsResponse: ProtobufCodable {
    internal typealias Protobuf = Proto_FileGetContentsResponse.FileContents

    internal init(protobuf proto: Protobuf) {
        self.init(fileId: .fromProtobuf(proto.fileID), contents: proto.contents)
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.fileID = fileId.toProtobuf()
            proto.contents = Data(contents)
        }
    }
}

#if compiler(<5.7)
    // Swift 5.7 added the conformance to data, despite to the best of my knowledge, not changing anything in the underlying type.
    extension FileContentsResponse: @unchecked Sendable {}
#else
    extension FileContentsResponse: Sendable {}
#endif
