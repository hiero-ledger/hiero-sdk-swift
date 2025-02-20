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
import SwiftProtobuf

/// Possible token types.
///
/// Apart from fungible and non-fungible, tokens can have either a common or
/// unique representation.
///
/// Only `fungibleCommon` and `nonFungibleUnique` are supported right now. More
/// may be added in the future.
public enum TokenType {
    /// Tokens are interchangeable value with one another, where any quantity of them has the same value as
    /// another equal quantity if they are in the same class.  Share a single set of properties, not
    /// distinct from one another. Simply represented as a balance or quantity to a given Hedera
    /// account.
    case fungibleCommon

    /// Tokens are unique,
    /// not interchangeable with other tokens of the same type as they typically have different values.
    /// Individually traced and can carry unique properties (e.g. serial number).
    case nonFungibleUnique
}

extension TokenType: TryProtobufCodable {
    internal typealias Protobuf = Proto_TokenType

    internal init(protobuf proto: Protobuf) throws {
        switch proto {
        case .fungibleCommon: self = .fungibleCommon
        case .nonFungibleUnique: self = .nonFungibleUnique
        case .UNRECOGNIZED(let value):
            throw HError.fromProtobuf("unrecognized token type \(value)")
        }
    }

    internal func toProtobuf() -> Protobuf {
        switch self {
        case .fungibleCommon:
            return .fungibleCommon
        case .nonFungibleUnique:
            return .nonFungibleUnique
        }
    }
}
