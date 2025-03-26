import SnapshotTesting
import XCTest

@testable import Hiero

internal final class AccountIdTests: XCTestCase {
    internal func testParse() {
        XCTAssertEqual(try AccountId.fromString("0.0.1001"), AccountId(num: 1001))
    }

    internal func testToFromBytesRoundtrip() {
        let accountId = AccountId(num: 1001)

        XCTAssertEqual(accountId, try AccountId.fromBytes(accountId.toBytes()))
    }

    internal func testFromEvmAddressString() {
        XCTAssertEqual(
            AccountId(evmAddress: "0x302a300506032b6570032100114e6abc371b82da", shard: 0, realm: 0),
            try AccountId.fromString("0x302a300506032b6570032100114e6abc371b82da")
        )
    }

    internal func testToEvmAddressString() {
        XCTAssertEqual(
            "0x302a300506032b6570032100114e6abc371b82da",
            AccountId(evmAddress: "0x302a300506032b6570032100114e6abc371b82da", shard: 0, realm: 0).toString()
        )
    }

    internal func testGoodChecksumOnMainnet() throws {
        let accountId = try AccountId.fromString("0.0.123-vfmkw")
        try accountId.validateChecksums(on: .mainnet)
    }

    internal func testGoodChecksumOnTestnet() throws {
        let accountId = try AccountId.fromString("0.0.123-esxsf")
        try accountId.validateChecksums(on: .testnet)
    }

    internal func testGoodChecksumOnPreviewnet() throws {
        let accountId = try AccountId.fromString("0.0.123-ogizo")
        try accountId.validateChecksums(on: .previewnet)
    }

    internal func testToStringWithChecksum() {
        let client = Client.forTestnet()

        XCTAssertEqual(
            "0.0.123-esxsf",
            try AccountId.fromString("0.0.123").toStringWithChecksum(client)
        )
    }

    internal func testBadChecksumOnPreviewnet() {
        let accountId: AccountId = "0.0.123-ntjli"

        XCTAssertThrowsError(try accountId.validateChecksums(on: .previewnet))
    }

    internal func testMalformedIdFails() {
        XCTAssertThrowsError(try AccountId.fromString("0.0."))
    }

    internal func testMalformedChecksum() {
        XCTAssertThrowsError(try AccountId.fromString("0.0.123-ntjl"))
    }

    internal func testMalformedChecksum2() {
        XCTAssertThrowsError(try AccountId.fromString("0.0.123-ntjl1"))
    }

    internal func testMalformedAlias() {
        XCTAssertThrowsError(
            try AccountId.fromString(
                "0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf777"))
    }
    internal func testMalformedAlias2() {
        XCTAssertThrowsError(
            try AccountId.fromString(
                "0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf777g"))
    }
    internal func testMalformedAliasKey3() {
        XCTAssertThrowsError(
            try AccountId.fromString(
                "0.0.303a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf7777"))
    }

    internal func testFromStringAliasKey() {
        assertSnapshot(
            matching: try AccountId.fromString(
                "0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf7777"),
            as: .description
        )
    }

    internal func testFromStringEvmAddress() {
        assertSnapshot(
            matching: try AccountId.fromString("0x302a300506032b6570032100114e6abc371b82da"),
            as: .description
        )
    }

    internal func testFromSolidityAddress() {
        assertSnapshot(
            matching: try AccountId.fromSolidityAddress("000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testFromSolidityAddress0x() {
        assertSnapshot(
            matching: try AccountId.fromSolidityAddress("0x000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testFromBytes() {
        assertSnapshot(
            matching: try AccountId.fromBytes(AccountId(num: 5005).toBytes()),
            as: .description
        )
    }

    internal func testFromBytesAlias() throws {
        let bytes = try AccountId.fromString(
            "0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf7777"
        ).toBytes()
        assertSnapshot(
            matching: try AccountId.fromBytes(bytes),
            as: .description
        )
    }

    internal func testFromBytesEvmAddress() throws {
        let bytes = try AccountId.fromString("0x302a300506032b6570032100114e6abc371b82da").toBytes()

        assertSnapshot(
            matching: try AccountId.fromBytes(bytes),
            as: .description
        )
    }

    internal func testToSolidityAddress() {
        assertSnapshot(
            matching: try AccountId(num: 5005).toSolidityAddress(),
            as: .lines
        )
    }

    internal func testFromEvmAddress() {
        assertSnapshot(
            matching: try AccountId(
                evmAddress: .fromString("0x302a300506032b6570032100114e6abc371b82da"), shard: 0, realm: 0),
            as: .description
        )
    }

    internal func testFromEvmAddressWithPrefix() throws {
        let evmAddressString = "0x302a300506032b6570032100114e6abc371b82da"
        let evmAddress = try EvmAddress.fromString(evmAddressString)
        let id1 = AccountId.fromEvmAddress(evmAddress, shard: 0, realm: 0)
        let id2 = try AccountId.fromEvmAddress(evmAddressString, shard: 0, realm: 0)

        XCTAssertEqual(id1, id2)
    }

    internal func testFromEvmAddressWithShardAndRealm() throws {
        let evmAddressString = "0x302a300506032b6570032100114e6abc371b82da"
        let evmAddress = try EvmAddress.fromString(evmAddressString)
        let id1 = AccountId.init(evmAddress: evmAddress, shard: 1, realm: 2)
        let id2 = try AccountId.fromEvmAddress(evmAddressString, shard: 1, realm: 2)

        XCTAssertEqual(id1, id2)
    }

}
