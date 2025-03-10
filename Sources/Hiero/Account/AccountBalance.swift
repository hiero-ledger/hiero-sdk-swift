// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

private struct TokenBalance: Sendable {
    fileprivate let id: TokenId
    fileprivate let balance: UInt64
    fileprivate let decimals: UInt32

    internal init(id: TokenId, balance: UInt64, decimals: UInt32) {
        self.id = id
        self.balance = balance
        self.decimals = decimals
    }
}

extension TokenBalance: ProtobufCodable {
    internal typealias Protobuf = Proto_TokenBalance

    internal init(protobuf proto: Protobuf) {
        self.init(id: .fromProtobuf(proto.tokenID), balance: proto.balance, decimals: proto.decimals)
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.tokenID = id.toProtobuf()
            proto.balance = balance
            proto.decimals = decimals
        }
    }
}

/// Response from ``AccountBalanceQuery``.
public struct AccountBalance: Sendable {
    /// The account that is being referenced.
    public let accountId: AccountId

    /// Current balance of the referenced account.
    public let hbars: Hbar

    private let tokensInner: [TokenBalance]

    // hack to work around deprecated warning
    private var tokenBalancesInner: [TokenId: UInt64] {
        Dictionary(uniqueKeysWithValues: tokensInner.map { ($0.id, $0.balance) })
    }

    /// Token balances for the referenced account.
    ///
    /// This access is *`O(n)`*.
    public var tokenBalances: [TokenId: UInt64] { tokenBalancesInner }

    // hack to work around deprecated warning
    public var tokenDecimalsInner: [TokenId: UInt32] {
        Dictionary(uniqueKeysWithValues: tokensInner.map { ($0.id, $0.decimals) })
    }

    /// Token decimals for the referenced account.
    ///
    /// This access is *`O(n)`*.
    @available(*, deprecated, message: "use a mirror query")
    public var tokenDecimals: [TokenId: UInt32] { tokenDecimalsInner }

    /// Decode `Self` from protobuf-encoded `bytes`.
    ///
    /// - Throws: ``HError/ErrorKind/fromProtobuf`` if:
    ///           decoding the bytes fails to produce a valid protobuf, or
    ///            decoding the protobuf fails.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Convert `self` to protobuf encoded data.
    public func toBytes() -> Data {
        toProtobufBytes()
    }

    /// Encode self as a string.
    public func toString() -> String {
        String(describing: self)
    }
}

extension AccountBalance: TryProtobufCodable {
    internal typealias Protobuf = Proto_CryptoGetAccountBalanceResponse

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            accountId: try .fromProtobuf(proto.accountID),
            hbars: .fromTinybars(Int64(proto.balance)),
            tokensInner: .fromProtobuf(proto.tokenBalances)
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.accountID = accountId.toProtobuf()
            proto.balance = UInt64(hbars.toTinybars())
            proto.tokenBalances = tokensInner.toProtobuf()
        }
    }
}
