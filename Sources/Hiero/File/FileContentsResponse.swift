/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

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
