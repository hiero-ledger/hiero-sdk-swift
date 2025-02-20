/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
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

import HieroProtobufs
import SwiftProtobuf

/// Possible token supply types.
/// Can be used to restrict supply to a set maximum.
///
/// Defaults to ``infinite``.
public enum TokenSupplyType {
    /// Indicates the token has a maximum supply of `UInt64.max`.
    case infinite
    /// Indicates the token has a configurable maximum supply, provided on token creation.
    case finite
}

extension TokenSupplyType: TryProtobufCodable {
    internal typealias Protobuf = Proto_TokenSupplyType

    internal init(protobuf proto: HieroProtobufs.Proto_TokenSupplyType) throws {
        switch proto {
        case .infinite:
            self = .infinite
        case .finite:
            self = .finite
        case .UNRECOGNIZED(let value):
            throw HError.fromProtobuf("unrecognized TokenSupplyType: `\(value)`")
        }
    }

    internal func toProtobuf() -> HieroProtobufs.Proto_TokenSupplyType {
        switch self {
        case .infinite:
            return .infinite
        case .finite:
            return .finite
        }
    }
}
