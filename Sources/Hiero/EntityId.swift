// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

public protocol EntityId: LosslessStringConvertible, ExpressibleByIntegerLiteral,
    ExpressibleByStringLiteral, Hashable
where
    Self.IntegerLiteralType == UInt64,
    Self.StringLiteralType == String
{
    /// The shard number (non-negative).
    var shard: UInt64 { get }

    /// The realm number (non-negative).
    var realm: UInt64 { get }

    /// The entity (account, file, contract, token, topic, or schedule) number (non-negative).
    var num: UInt64 { get }

    /// The checksum for this entity ID with respect to *some* ledger ID.
    var checksum: Checksum? { get }

    /// Create an entity ID in the default shard and realm with the given entity number.
    ///
    /// - Parameters:
    ///   - num: the entity number for the entity.
    init(num: UInt64)

    /// Creates an entity ID from the given shard, realm, and entity numbers.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the entity is contained.
    ///   - realm: the realm in which the entity is contained.
    ///   - num: the entity number for the entity.
    init(shard: UInt64, realm: UInt64, num: UInt64)

    /// Creates an entity ID from the given shard, realm, and entity numbers, and with the given checksum.
    ///
    /// - Parameters:
    ///   - shard: the shard in which the entity is contained.
    ///   - realm: the realm in which the entity is contained.
    ///   - num: the entity number for the entity.
    ///   - checksum: the 5 character checksum of the entity.
    init(shard: UInt64, realm: UInt64, num: UInt64, checksum: Checksum?)

    /// Creates an entity ID from the given shard, realm, and EVM address.
    ///
    /// - Parameters:
    ///   - evmAddress: the EVM address from which to generate the entity ID.
    ///   - shard: the shard in which the entity is contained.
    ///   - realm: the realm in which the entity is contained.
    init(evmAddress: EvmAddress, shard: UInt64, realm: UInt64)

    /// Creates an entity ID from a string.
    ///
    /// - Parameters:
    ///   - description: the string to parse.
    init<S: StringProtocol>(parsing description: S) throws

    /// Creates an entity ID from a string.
    ///
    /// - Parameters:
    ///   - description: the string to parse.
    static func fromString<S: StringProtocol>(_ description: S) throws -> Self

    /// Converts this entity ID to a string.
    func toString() -> String

    /// Converts this entity ID to a string with its checksum.
    ///
    /// - Parameters:
    ///   - client: The client to use to generate the checksum.
    func toStringWithChecksum(_ client: Client) throws -> String

    /// Creates an entity ID from the given bytes.
    ///
    /// - Parameters:
    ///   - bytes: the bytes to parse.
    static func fromBytes(_ bytes: Data) throws -> Self

    /// Converts this entity ID to bytes.
    func toBytes() -> Data

    /// Creates an entity ID from an EVM address.
    ///
    /// - Parameters:
    ///   - evmAddress: The EVM address from which generate the entity ID.
    ///   - shard: The shard of the entity.
    ///   - realm: The realm of the entity.
    static func fromEvmAddress(_ evmAddress: EvmAddress, shard: UInt64, realm: UInt64) throws -> Self

    /// Creates an entity ID from a string EVM address.
    ///
    /// - Parameters:
    ///   - evmAddress: The EVM address string from which to generate the entity ID.
    ///   - shard: The shard of the entity.
    ///   - realm: The realm of the entity.
    static func fromEvmAddress(_ evmAddress: String, shard: UInt64, realm: UInt64) throws -> Self

    /// Converts this entity ID to an EVM address.
    func toEvmAddress() throws -> EvmAddress

    /// Validates the checksum of this entity ID.
    ///
    /// - Parameters:
    ///   - client: The client to use to validate the checksum.
    func validateChecksum(_ client: Client) throws

    /// *Deprecated* Creates an entity ID from a solidity address.
    ///
    /// - Parameters:
    ///   - description: the solidity address to parse.
    @available(*, deprecated, message: "Use fromEvmAddress(_shard:realm:) instead")
    static func fromSolidityAddress<S: StringProtocol>(_ description: S) throws -> Self

    /// *Deprecated* Converts this entity ID into a solidity address.
    @available(*, deprecated, message: "Use toEvmAddress() instead")
    func toSolidityAddress() throws -> String
}

extension EntityId {
    internal typealias Helper = EntityIdHelper<Self>

    internal var helper: Helper { Helper(self) }

    /// The stringified entity ID.
    public var description: String { helper.description }

    /// Creates an entity ID in the default shard and realm with the given entity number.
    ///
    /// - Parameters:
    ///   - num: the entity number for the new entity.
    public init(num: UInt64) {
        self.init(shard: 0, realm: 0, num: num)
    }

    /// Creates an entity ID in the default shard and realm with the given entity number literal.
    ///
    /// - Parameters:
    ///   - num: the entity number for the new entity.
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(num: value)
    }

    /// Creates an entity ID from the given shard, realm, and EVM address.
    ///
    /// - Parameters:
    ///   - evmAddress: the EVM address from which to get the entity number to use for the new entity.
    ///   - shard: the shard in which the entity is contained.
    ///   - realm: the realm in which the entity is contained.
    public init(evmAddress: EvmAddress, shard: UInt64, realm: UInt64) {
        self.init(
            shard: shard, realm: realm,
            num: evmAddress.toBytes().suffix(from: 12).withUnsafeBytes { rawBuffer -> UInt64 in
                var result: UInt64 = 0
                withUnsafeMutableBytes(of: &result) { resultBuffer in
                    resultBuffer.copyBytes(from: rawBuffer.prefix(8))
                }
                return UInt64(bigEndian: result)
            })
    }

    /// Creates an entity ID from a string.
    ///
    /// - Parameters:
    ///   - description: the string to parse.
    public init<S: StringProtocol>(parsing description: S) throws {
        self = try PartialEntityId(parsing: description).intoNum()
    }

    /// Creates an entity ID from a string literal.
    ///
    /// - Parameters:
    ///   - description: the string to parse.
    public init(stringLiteral value: StringLiteralType) {
        // Force try here because this is a logic error.
        // swiftlint:disable:next force_try
        try! self.init(parsing: value)
    }

    /// Creates an entity ID from a string.
    ///
    /// - Parameters:
    ///   - description: the string to parse.
    public init?(_ description: String) {
        try? self.init(parsing: description)
    }

    /// Creates an entity ID from a string.
    ///
    /// - Parameters:
    ///   - description: the string to parse.
    public static func fromString<S: StringProtocol>(_ description: S) throws -> Self {
        try Self(parsing: description)
    }

    /// Converts this entity ID to a string.
    public func toString() -> String {
        String(describing: self)
    }

    /// Converts this entity ID to a string with its checksum.
    ///
    /// - Parameters:
    ///   - client: The client to use to generate the checksum.
    public func toStringWithChecksum(_ client: Client) -> String {
        return helper.toStringWithChecksum(client)
    }

    /// Creates an entity ID from an EVM address.
    ///
    /// - Parameters:
    ///   - evmAddress: The EVM address from which to generate the entity ID.
    ///   - shard: The shard of the entity.
    ///   - realm: The realm of the entity.
    public static func fromEvmAddress(_ evmAddress: EvmAddress, shard: UInt64, realm: UInt64) throws -> Self {
        Self(evmAddress: evmAddress, shard: shard, realm: realm)
    }

    /// Creates an entity ID from a string EVM address.
    ///
    /// - Parameters:
    ///   - evmAddress: The EVM address string from which to generate the entity ID.
    ///   - shard: The shard of the entity.
    ///   - realm: The realm of the entity.
    public static func fromEvmAddress(_ evmAddress: String, shard: UInt64, realm: UInt64) throws -> Self {
        Self(evmAddress: try EvmAddress.fromString(evmAddress), shard: shard, realm: realm)
    }

    /// Converts this entity ID to an EVM address.
    public func toEvmAddress() throws -> EvmAddress {
        var bigEndianValue = num.bigEndian
        return try EvmAddress.fromBytes(
            Data(repeating: 0, count: 12) + withUnsafeBytes(of: &bigEndianValue) { Data($0) })
    }

    /// Validates the checksum of this entity ID.
    ///
    /// - Parameters:
    ///   - client: The client to use to validate the checksum.
    public func validateChecksum(_ client: Client) throws {
        try helper.validateChecksum(on: client)
    }

    /// Generates the checksum for this entity ID.
    ///
    /// - Parameters:
    ///   - ledgerId: The ledger ID to use to generate the checksum.
    internal func makeChecksum(ledger ledgerId: LedgerId) -> Checksum {
        Checksum.generate(for: self, on: ledgerId)
    }

    /// *Deprecated* Creates an entity ID from a string solidity address.
    ///
    /// - Parameters:
    ///   - description: the string solidity address to parse.
    @available(*, deprecated, message: "Use fromEvmAddress(_shard:realm:) instead")
    public static func fromSolidityAddress<S: StringProtocol>(_ description: S) throws -> Self {
        try SolidityAddress(parsing: description).toEntityId()
    }

    /// *Deprecated* Converts this entity ID into a solidity address.
    @available(*, deprecated, message: "Use toEvmAddress() instead")
    public func toSolidityAddress() throws -> String {
        try String(describing: SolidityAddress(self))
    }
}

// this exists purely for convinence purposes lol.
internal struct EntityIdHelper<E: EntityId> {
    internal init(_ id: E) {
        self.id = id
    }

    private let id: E

    internal var description: String {
        "\(id.shard).\(id.realm).\(id.num)"
    }

    // note: this *expicitly* ignores the current checksum.
    internal func toStringWithChecksum(_ client: Client) -> String {
        let checksum = id.makeChecksum(ledger: client.ledgerId!)
        return "\(description)-\(checksum)"
    }

    internal func validateChecksum(on ledgerId: LedgerId) throws {
        guard let checksum = id.checksum else {
            return
        }

        let expected = id.makeChecksum(ledger: ledgerId)

        guard checksum == expected else {
            throw HError.badEntityId(
                shard: id.shard, realm: id.realm, num: id.num, presentChecksum: checksum, expectedChecksum: expected
            )
        }
    }

    internal func validateChecksum(on client: Client) throws {
        try validateChecksum(on: client.ledgerId!)
    }
}

internal enum PartialEntityId<S: StringProtocol> {
    // entity ID in the form `<num>`
    case short(num: UInt64)
    // entity ID in the form `<shard>.<realm>.<last>`
    case long(shard: UInt64, realm: UInt64, last: S.SubSequence, checksum: Checksum?)
    // entity ID in some other format (for example `0x<evmAddress>`)
    case other(S.SubSequence)

    internal init(parsing description: S) throws {
        switch description.splitOnce(on: ".") {
        case .some((let shard, let rest)):
            // `shard.realm.num` format
            guard let (realm, rest) = rest.splitOnce(on: ".") else {
                throw HError(
                    kind: .basicParse, description: "expected `<shard>.<realm>.<num>` or `<num>`, got, \(description)")
            }

            let (last, checksum) = try rest.splitOnce(on: "-").map { ($0, try Checksum(parsing: $1)) } ?? (rest, nil)

            self = .long(
                shard: try UInt64(parsing: shard),
                realm: try UInt64(parsing: realm),
                last: last,
                checksum: checksum
            )

        case .none:
            self = UInt64(description).map(Self.short) ?? .other(description[...])
        }
    }

    internal func intoNum<E: EntityId>() throws -> E {
        switch self {
        case .short(let num):
            return E(num: num)
        case .long(let shard, let realm, last: let num, let checksum):
            return E(shard: shard, realm: realm, num: try UInt64(parsing: num), checksum: checksum)
        case .other(let description):
            throw HError(
                kind: .basicParse, description: "expected `<shard>.<realm>.<num>` or `<num>`, got, \(description)")
        }
    }
}
