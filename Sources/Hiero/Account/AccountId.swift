// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The unique identifier for a cryptocurrency account on Hiero.
public struct AccountId: Sendable, EntityId, ValidateChecksums {
    public let shard: UInt64
    public let realm: UInt64
    public let num: UInt64
    public let alias: PublicKey?
    public let evmAddress: EvmAddress?
    public let checksum: Checksum?

    /// The stringified account ID.
    public var description: String {
        if let alias = alias {
            return "\(shard).\(realm).\(alias)"
        }

        if let evmAddress = evmAddress {
            return evmAddress.toString()
        }

        return helper.description
    }

    /// Creates an account ID from the given shard, realm, and account numbers.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the account is contained. Defaults to 0.
    ///   - realm: the realm in which the account is contained. Defaults to 0.
    ///   - num: the account number for the account.
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64) {
        self.init(shard: shard, realm: realm, num: num, checksum: nil)
    }

    /// Creates an account ID from the given shard, realm, and account numbers, and with the given checksum.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the account is contained.
    ///   - realm: the realm in which the account is contained.
    ///   - num: the account number for the account.
    ///   - checksum: the 5 character checksum of the account.
    public init(shard: UInt64, realm: UInt64, num: UInt64, checksum: Checksum?) {
        self.shard = shard
        self.realm = realm
        self.num = num
        self.alias = nil
        self.evmAddress = nil
        self.checksum = checksum
    }

    /// Creates an account ID from the given shard, realm, and alias.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the account is contained. Defaults to 0.
    ///   - realm: the realm in which the account is contained. Defaults to 0.
    ///   - alias: the public key to act as the alias account.
    public init(shard: UInt64 = 0, realm: UInt64 = 0, alias: PublicKey) {
        self.shard = shard
        self.realm = realm
        self.num = 0
        self.alias = alias
        self.evmAddress = nil
        self.checksum = nil
    }

    /// Creates an account ID from the given shard, realm, and EVM address.
    ///
    /// - Parameters:
    ///   - evmAddress: the EVM address to act as the alias for the account.
    ///   - shard: the shard in which the account is contained.
    ///   - realm: the realm in which the account is contained.
    public init(evmAddress: EvmAddress, shard: UInt64, realm: UInt64) {
        self.shard = shard
        self.realm = realm
        self.num = 0
        self.alias = nil
        self.evmAddress = evmAddress
        self.checksum = nil
    }

    /// Creates an account ID from a string.
    ///
    /// - Parameters:
    ///   - description: the string to parse.
    public init<S: StringProtocol>(parsing description: S) throws {
        switch try PartialEntityId(parsing: description) {
        case .short(let num):
            self.init(num: num)

        case .long(let shard, let realm, let last, let checksum):
            if let num = UInt64(last) {
                self.init(shard: shard, realm: realm, num: num, checksum: checksum)
            } else {
                guard checksum == nil else {
                    throw HError(
                        kind: .basicParse, description: "checksum not supported with `<shard>.<realm>.<alias>`")
                }

                // might have `alias`
                self.init(
                    shard: shard,
                    realm: realm,
                    alias: try PublicKey.fromString(String(last))
                )
            }

        case .other(let description):
            let evmAddress = try EvmAddress(parsing: description)

            self.init(evmAddress: evmAddress, shard: 0, realm: 0)
        }
    }

    /// Converts this account ID to a string with its checksum.
    ///
    /// - Parameters:
    ///   - client: The client to use to generate the checksum.
    public func toStringWithChecksum(_ client: Client) throws -> String {
        guard alias == nil, evmAddress == nil else {
            throw HError.cannotCreateChecksum
        }

        return helper.toStringWithChecksum(client)
    }

    /// Creates an account ID from the given bytes.
    ///
    /// - Parameters:
    ///   - bytes: the bytes to parse.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Converts this account ID to bytes.
    public func toBytes() -> Data {
        toProtobufBytes()
    }

    /// Converts this account ID to an EVM address.
    public func toEvmAddress() throws -> EvmAddress {
        if let evmAddress = self.evmAddress {
            return evmAddress
        }

        return try (self as any EntityId).toEvmAddress()
    }

    /// Validates the checksum of this account ID.
    ///
    /// - Parameters:
    ///   - client: The client to use to validate the checksum.
    public func validateChecksum(_ client: Client) throws {
        try validateChecksums(on: client.ledgerId!)
    }

    /// Validates the checksum of this account ID.
    ///
    /// - Parameters:
    ///   - ledgerId: The ledger ID to use to validate the checksum.
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        if alias != nil || evmAddress != nil {
            return
        }

        try helper.validateChecksum(on: ledgerId)
    }

    /// *Deprecated* Creates an account ID from an EVM address.
    ///
    /// - Parameters:
    ///   - evmAddress: the EVM address to act as the alias for the new account.
    @available(*, deprecated, message: "Use init(evmAddress:shard:realm:) instead")
    public init(evmAddress: EvmAddress) {
        self.shard = 0
        self.realm = 0
        self.num = 0
        self.checksum = nil
        self.alias = nil
        self.evmAddress = evmAddress
    }

    /// *Deprecated* Creates an account Id from an EVM address.
    ///
    /// - Parameters:
    ///   - evmAddress: the EVM address to act as the alias for the new account.
    @available(
        *, deprecated, message: "Use fromEvmAddress(evmAddress:shard:realm:) instead"
    )
    public static func fromEvmAddress(_ evmAddress: EvmAddress) -> Self {
        Self(evmAddress: evmAddress)
    }
}

extension AccountId: TryProtobufCodable {
    internal typealias Protobuf = Proto_AccountID

    /// Creates an account ID from an account ID protobuf.
    ///
    /// - Parameters:
    ///   - proto: the account ID protobuf.
    internal init(protobuf proto: Protobuf) throws {
        let shard = UInt64(proto.shardNum)
        let realm = UInt64(proto.realmNum)

        switch proto.account {
        case .accountNum(let num):
            self.init(shard: shard, realm: realm, num: UInt64(num))
        case .alias(let data):
            switch try? EvmAddress.fromBytes(data) {
            case .some(let evmAddress): self.init(evmAddress: evmAddress, shard: shard, realm: realm)
            case nil: self.init(shard: shard, realm: realm, alias: try PublicKey(protobufBytes: data))
            }

        case nil: throw HError.fromProtobuf("Unexpected missing `account`")
        }
    }

    /// Converts this account ID to an account ID protobuf.
    internal func toProtobuf() -> Protobuf {
        .with { proto in
            if let evmAddress = evmAddress {
                proto.alias = evmAddress.data
                return
            }

            proto.shardNum = Int64(shard)
            proto.realmNum = Int64(realm)

            if let alias = alias {
                proto.alias = alias.toProtobufBytes()
            } else {
                proto.accountNum = Int64(num)
            }
        }
    }
}
