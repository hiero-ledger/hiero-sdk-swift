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
    ///   - num: the number for the new entity ID.
    init(num: UInt64)

    /// Creates an entity ID from the given shard, realm, and entity numbers.
    ///
    /// - Parameters:
    ///   - shard: the shard that the realm is contained in.
    ///   - realm: the realm that the entity number is contained in.
    ///   - num: the entity ID in the given shard and realm.
    init(shard: UInt64, realm: UInt64, num: UInt64)

    /// Creates an entity ID from the given shard, realm, and entity numbers, and with the given checksum.
    ///
    /// - Parameters:
    ///   - shard: the shard that the realm is contained in.
    ///   - realm: the realm that the entity number is contained in.
    ///   - num: the entity ID in the given shard and realm.
    ///   - checksum: a 5 character checksum to help ensure a user-entered entity ID is correct.
    init(shard: UInt64, realm: UInt64, num: UInt64, checksum: Checksum?)

    /// Parse an entity ID from a string.
    init<S: StringProtocol>(parsing description: S) throws

    /// Parse an entity ID from a string.
    static func fromString<S: StringProtocol>(_ description: S) throws -> Self

    /// Parse an entity ID from the given `bytes`.
    static func fromBytes(_ bytes: Data) throws -> Self

    /// Convert this entity ID to bytes.
    func toBytes() -> Data

    /// Convert this entity ID to a string.
    func toString() -> String

    func toStringWithChecksum(_ client: Client) throws -> String

    func validateChecksum(_ client: Client) throws

    /// Create `Self` from a solidity `address`.
    static func fromSolidityAddress<S: StringProtocol>(_ description: S) throws -> Self

    /// Convert `self` into a solidity `address`
    func toSolidityAddress() throws -> String
}

extension EntityId {
    internal typealias Helper = EntityIdHelper<Self>

    internal var helper: Helper { Helper(self) }

    // swiftlint:disable:next missing_docs
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(num: value)
    }

    // inherited docs.
    // swiftlint:disable:next missing_docs
    public init(num: UInt64) {
        self.init(shard: 0, realm: 0, num: num)
    }

    // inherited docs.
    // swiftlint:disable:next missing_docs
    public init<S: StringProtocol>(parsing description: S) throws {
        self = try PartialEntityId(parsing: description).intoNum()
    }

    // inherited docs.
    // swiftlint:disable:next missing_docs
    public init?(_ description: String) {
        try? self.init(parsing: description)
    }

    // inherited docs.
    // swiftlint:disable:next missing_docs
    public init(stringLiteral value: StringLiteralType) {
        // Force try here because this is a logic error.
        // swiftlint:disable:next force_try
        try! self.init(parsing: value)
    }

    // inherited docs.
    // swiftlint:disable:next missing_docs
    public static func fromString<S: StringProtocol>(_ description: S) throws -> Self {
        try Self(parsing: description)
    }

    // inherited docs.
    // swiftlint:disable:next missing_docs
    public var description: String { helper.description }

    // inherited docs.
    // swiftlint:disable:next missing_docs
    public static func fromSolidityAddress<S: StringProtocol>(_ description: S) throws -> Self {
        try SolidityAddress(parsing: description).toEntityId()
    }

    // inherited docs.
    // swiftlint:disable:next missing_docs
    public func toString() -> String {
        String(describing: self)
    }

    internal func makeChecksum(ledger ledgerId: LedgerId) -> Checksum {
        Checksum.generate(for: self, on: ledgerId)
    }

    // inherited docs.
    // swiftlint:disable:next missing_docs
    public func toStringWithChecksum(_ client: Client) -> String {
        helper.toStringWithChecksum(client)
    }

    // inherited docs.
    // swiftlint:disable:next missing_docs
    public func validateChecksum(_ client: Client) throws {
        try helper.validateChecksum(on: client)
    }

    // inherited docs.
    // swiftlint:disable:next missing_docs
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

// fixme(sr): How do DRY?

/// The unique identifier for a file on Hiero.
public struct FileId: EntityId, ValidateChecksums, Sendable {
    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64, checksum: Checksum?) {
        self.shard = shard
        self.realm = realm
        self.num = num
        self.checksum = checksum
    }

    public init(shard: UInt64 = 0, realm: UInt64 = 0, num: UInt64) {
        self.init(shard: shard, realm: realm, num: num, checksum: nil)
    }

    public let shard: UInt64
    public let realm: UInt64

    /// The file number.
    public let num: UInt64

    public let checksum: Checksum?

    public static let addressBook: FileId = 102
    public static let feeSchedule: FileId = 111
    public static let exchangeRates: FileId = 112

    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    public func toBytes() -> Data {
        toProtobufBytes()
    }

    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try helper.validateChecksum(on: ledgerId)
    }
}

extension FileId: ProtobufCodable {
    internal typealias Protobuf = HieroProtobufs.Proto_FileID

    internal init(protobuf proto: Protobuf) {
        self.init(
            shard: UInt64(proto.shardNum),
            realm: UInt64(proto.realmNum),
            num: UInt64(proto.fileNum)
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.shardNum = Int64(shard)
            proto.realmNum = Int64(realm)
            proto.fileNum = Int64(num)
        }
    }
}
