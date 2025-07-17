// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

// fixme(sr,docs): describe what a Delegate contract ID is actually for / what it does / etc.
/// A unique identifier for a smart contract on Hiero.
public struct DelegateContractId: Sendable, EntityId {
    private init(_ inner: ContractId) {
        self.inner = inner
    }

    private let inner: ContractId

    /// A non-negative number identifying the shard containing this contract instance.
    public var shard: UInt64 { inner.shard }

    /// A non-negative number identifying the realm within the shard containing this contract instance.
    public var realm: UInt64 { inner.realm }

    /// A non-negative number identifying the entity within the realm containing this contract instance.
    ///
    /// >Note: Exactly one of `evmAddress` and `num` must exist.
    public var num: UInt64 { inner.num }

    /// A checksum if the contract ID was read from a user inputted string which included a checksum
    public var checksum: Checksum? { inner.checksum }

    /// EVM address identifying the entity within the realm containing this contract instance.
    ///
    /// >Note: Exactly one of `evm_address` and `num` must exist.
    public var evmAddress: EvmAddress? { inner.evmAddress }

    /// Create a DelegateContractId from the given shard/realm/num
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64, checksum: Checksum?) {
        inner = .init(shard: shard, realm: realm, num: num, checksum: checksum)
    }

    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64) {
        self.init(shard: shard, realm: realm, num: num, checksum: nil)
    }

    public init<S: StringProtocol>(parsing description: S) throws {
        inner = try ContractId(parsing: description)
    }

    public var description: String {
        String(describing: inner)
    }

    public static func fromBytes(_ bytes: Data) throws -> DelegateContractId {
        try Self(protobufBytes: bytes)
    }

    public func toBytes() -> Data {
        inner.toBytes()
    }
}

extension DelegateContractId: TryProtobufCodable {
    internal typealias Protobuf = ContractId.Protobuf

    internal init(protobuf proto: Protobuf) throws {
        self.init(try ContractId(protobuf: proto))
    }

    internal func toProtobuf() -> Protobuf {
        inner.toProtobuf()
    }
}
