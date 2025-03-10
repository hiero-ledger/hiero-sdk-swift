// SPDX-License-Identifier: Apache-2.0

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
