// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The unique identifier for a smart contract on Hiero.
public struct ContractId: EntityId, ValidateChecksums {
    public let shard: UInt64
    public let realm: UInt64
    public let num: UInt64
    public let evmAddress: EvmAddress?
    public let checksum: Checksum?

    /// The stringified contract ID.
    public var description: String {
        if let evmAddress = evmAddress {
            return "\(shard).\(realm)." + String(describing: evmAddress)
        }

        return helper.description
    }

    /// Creates a contract ID from the given shard, realm, and contract numbers.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the contract is contained. Defaults to 0.
    ///   - realm: the realm in which the contract is contained. Defaults to 0.
    ///   - num: the contract number for the contract.
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64) {
        self.init(shard: shard, realm: realm, num: num, checksum: nil)
    }

    /// Creates a contract ID from the given shard, realm, and contract numbers, and with the given checksum.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the contract is contained.
    ///   - realm: the realm in which the contract is contained.
    ///   - num: the contract number for the contract.
    ///   - checksum: the 5 character checksum of the contract.
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64, checksum: Checksum?) {
        self.shard = shard
        self.realm = realm
        self.num = num
        self.evmAddress = nil
        self.checksum = checksum
    }

    /// Creates a contract ID from the given shard, realm, and EVM address.
    ///
    /// - Parameters:
    ///   - evmAddress: the EVM address to act as the alias for the contract.
    ///   - shard: the shard in which the contract is contained.
    ///   - realm: the realm in which the contract is contained.
    public init(evmAddress: EvmAddress, shard: UInt64, realm: UInt64) {
        self.shard = shard
        self.realm = realm
        self.num = 0
        self.evmAddress = evmAddress
        self.checksum = nil
    }

    /// Creates a contract ID from a string.
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
                return
            }

            // might have `evmAddress`
            guard let evmAddress = Data(hexEncoded: last.stripPrefix("0x") ?? last) else {
                throw HError(
                    kind: .basicParse,
                    description:
                        "expected `<shard>.<realm>.<num>` or `<shard>.<realm>.<evmAddress>`, got, \(description)")
            }

            guard evmAddress.count == 20 else {
                throw HError.basicParse("expected `20` byte evm address, got `\(evmAddress.count)` bytes")
            }

            guard checksum == nil else {
                throw HError(
                    kind: .basicParse, description: "checksum not supported with `<shard>.<realm>.<evmAddress>`")
            }

            self.init(evmAddress: try EvmAddress.fromBytes(evmAddress), shard: shard, realm: realm)

        case .other(let description):
            throw HError(
                kind: .basicParse,
                description: "expected `<shard>.<realm>.<num>` or `<shard>.<realm>.<evmAddress>`, got, \(description)")
        }
    }

    /// Converts this contract ID to a string with its checksum.
    ///
    /// - Parameters:
    ///   - client: The client to use to generate the checksum.
    public func toStringWithChecksum(_ client: Client) throws -> String {
        guard evmAddress == nil else {
            throw HError.cannotCreateChecksum
        }

        return helper.toStringWithChecksum(client)
    }

    /// Creates a contract ID from the given bytes.
    ///
    /// - Parameters:
    ///   - bytes: the bytes to parse.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Converts this contract ID to bytes.
    public func toBytes() -> Data {
        toProtobufBytes()
    }

    /// Converts this contract ID to an EVM address.
    public func toEvmAddress() throws -> EvmAddress {
        if let evmAddress = self.evmAddress {
            return evmAddress
        }

        return try (self as any EntityId).toEvmAddress()
    }

    /// Validates the checksum of this contract ID.
    ///
    /// - Parameters:
    ///   - client: The client to use to validate the checksum.
    public func validateChecksum(_ client: Client) throws {
        try validateChecksums(on: client.ledgerId!)
    }

    /// Validates the checksum of this contract ID.
    ///
    /// - Parameters:
    ///   - ledgerId: The ledger ID to use to validate the checksum.
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        guard evmAddress == nil else {
            return
        }

        try helper.validateChecksum(on: ledgerId)
    }

    /// *Deprecated* Creates a contract ID from a string EVM address.
    ///
    /// - Parameters:
    ///   - shard: the shard of the contract.
    ///   - realm: the realm of the contract.
    ///   - address: the EVM address to act as the alias for the new contract.
    @available(*, deprecated, message: "Use fromEvmAddress(_:shard:realm:) instead")
    public static func fromEvmAddress(_ shard: UInt64, _ realm: UInt64, _ address: String) throws -> Self {
        Self(evmAddress: try EvmAddress.fromBytes(SolidityAddress(parsing: address).data), shard: shard, realm: realm)
    }

    /// *Deprecated* Creates a contract ID from a serialized EVM address.
    ///
    /// - Parameters:
    ///   - shard: the shard of the contract.
    ///   - realm: the realm of the contract.
    ///   - address: the EVM address to act as the alias for the new contract.
    @available(*, deprecated, message: "Use fromEvmAddress(_:shard:realm:) instead")
    internal static func fromEvmAddressBytes(_ shard: UInt64, _ realm: UInt64, _ address: Data) throws -> Self {
        Self(evmAddress: try EvmAddress.fromBytes(SolidityAddress(address).data), shard: shard, realm: realm)
    }

    /// *Deprecated* Converts this contract ID to a solidity address.
    @available(*, deprecated, message: "Use toEvmAddress() instead")
    public func toSolidityAddress() throws -> String {
        if let evmAddress = evmAddress {
            return String(evmAddress.toString().dropFirst(2))
        }

        return String(describing: try SolidityAddress(self))

    }
}

#if compiler(>=5.7)
    extension ContractId: Sendable {}
#else
    // Swift 5.7 added the conformance to data, despite to the best of my knowledge, not changing anything in the underlying type.
    extension ContractId: @unchecked Sendable {}
#endif

extension ContractId: TryProtobufCodable {
    internal typealias Protobuf = Proto_ContractID

    /// Creates a contract ID from a contract ID protobuf.
    ///
    /// - Parameters:
    ///   - proto: the contract ID protobuf.
    internal init(protobuf proto: Protobuf) throws {
        let shard = UInt64(proto.shardNum)
        let realm = UInt64(proto.realmNum)
        guard let contract = proto.contract else {
            throw HError.fromProtobuf("unexpected missing `contract` field")
        }

        switch contract {
        case .contractNum(let num):
            self.init(shard: shard, realm: realm, num: UInt64(num))
        case .evmAddress(let evmAddress):
            self.init(evmAddress: try EvmAddress.fromBytes(evmAddress), shard: shard, realm: realm)
        }
    }

    /// Converts this contract ID to a contract ID protobuf.
    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.shardNum = Int64(shard)
            proto.realmNum = Int64(realm)
            if let evmAddress = evmAddress {
                proto.evmAddress = evmAddress.toBytes()
            } else {
                proto.contractNum = Int64(num)
            }
        }
    }
}
