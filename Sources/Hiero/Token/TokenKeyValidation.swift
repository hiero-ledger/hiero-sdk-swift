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

import Foundation
import HieroProtobufs

public enum TokenKeyValidation {
    /// Currently the default behaviour. It will perform all token key validations.
    case fullValidation
    /// Perform no validations at all for all passed token keys.
    case noValidation
    /// The passed token key is not recognized.
    case unrecognized(Int)
}

extension TokenKeyValidation: TryFromProtobuf {
    internal typealias Protobuf = Proto_TokenKeyValidation

    internal init(protobuf proto: Protobuf) throws {
        switch proto {
        case .fullValidation: self = .fullValidation
        case .noValidation: self = .noValidation
        case .UNRECOGNIZED(let value): self = .unrecognized(value)
        }
    }

    func toProtobuf() -> Protobuf {
        switch self {
        case .fullValidation:
            return .fullValidation
        case .noValidation:
            return .noValidation
        case .unrecognized(let value):
            return .UNRECOGNIZED(value)
        }
    }
}
