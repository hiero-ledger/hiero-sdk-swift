// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class AccountIdUnitTests: HieroUnitTestCase {
    internal func test_Parse() {
        XCTAssertEqual(try AccountId.fromString("0.0.1001"), AccountId(num: 1001))
    }

    internal func test_ToFromBytesRoundtrip() {
        let accountId = AccountId(num: 1001)

        XCTAssertEqual(accountId, try AccountId.fromBytes(accountId.toBytes()))
    }

    internal func test_FromEvmAddressString() {
        XCTAssertEqual(
            AccountId(evmAddress: "0x302a300506032b6570032100114e6abc371b82da", shard: 0, realm: 0),
            try AccountId.fromString("0x302a300506032b6570032100114e6abc371b82da")
        )
    }

    internal func test_ToEvmAddressString() {
        XCTAssertEqual(
            "0x302a300506032b6570032100114e6abc371b82da",
            AccountId(evmAddress: "0x302a300506032b6570032100114e6abc371b82da", shard: 0, realm: 0).toString()
        )
    }

    internal func test_GoodChecksumOnMainnet() throws {
        let accountId = try AccountId.fromString("0.0.123-vfmkw")
        try accountId.validateChecksums(on: .mainnet)
    }

    internal func test_GoodChecksumOnTestnet() throws {
        let accountId = try AccountId.fromString("0.0.123-esxsf")
        try accountId.validateChecksums(on: .testnet)
    }

    internal func test_GoodChecksumOnPreviewnet() throws {
        let accountId = try AccountId.fromString("0.0.123-ogizo")
        try accountId.validateChecksums(on: .previewnet)
    }

    internal func test_ToStringWithChecksum() {
        let client = Client.forTestnet()

        XCTAssertEqual(
            "0.0.123-esxsf",
            try AccountId.fromString("0.0.123").toStringWithChecksum(client)
        )
    }

    internal func test_BadChecksumOnPreviewnet() {
        let accountId: AccountId = "0.0.123-ntjli"

        XCTAssertThrowsError(try accountId.validateChecksums(on: .previewnet))
    }

    internal func test_MalformedIdFails() {
        XCTAssertThrowsError(try AccountId.fromString("0.0."))
    }

    internal func test_MalformedChecksum() {
        XCTAssertThrowsError(try AccountId.fromString("0.0.123-ntjl"))
    }

    internal func test_MalformedChecksum2() {
        XCTAssertThrowsError(try AccountId.fromString("0.0.123-ntjl1"))
    }

    internal func test_MalformedAlias() {
        XCTAssertThrowsError(
            try AccountId.fromString(
                "0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf777"))
    }
    internal func test_MalformedAlias2() {
        XCTAssertThrowsError(
            try AccountId.fromString(
                "0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf777g"))
    }
    internal func test_MalformedAliasKey3() {
        XCTAssertThrowsError(
            try AccountId.fromString(
                "0.0.303a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf7777"))
    }

    internal func test_FromStringAliasKey() {
        SnapshotTesting.assertSnapshot(
            of: try AccountId.fromString(
                "0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf7777"),
            as: .description
        )
    }

    internal func test_FromStringEvmAddress() {
        SnapshotTesting.assertSnapshot(
            of: try AccountId.fromString("0x302a300506032b6570032100114e6abc371b82da"),
            as: .description
        )
    }

    internal func test_FromSolidityAddress() {
        SnapshotTesting.assertSnapshot(
            of: try AccountId.fromSolidityAddress("000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func test_FromSolidityAddress0x() {
        SnapshotTesting.assertSnapshot(
            of: try AccountId.fromSolidityAddress("0x000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func test_FromBytes() {
        SnapshotTesting.assertSnapshot(
            of: try AccountId.fromBytes(AccountId(num: 5005).toBytes()),
            as: .description
        )
    }

    internal func test_FromBytesAlias() throws {
        let bytes = try AccountId.fromString(
            "0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf7777"
        ).toBytes()
        SnapshotTesting.assertSnapshot(
            of: try AccountId.fromBytes(bytes),
            as: .description
        )
    }

    internal func test_FromBytesEvmAddress() throws {
        let bytes = try AccountId.fromString("0x302a300506032b6570032100114e6abc371b82da").toBytes()

        SnapshotTesting.assertSnapshot(
            of: try AccountId.fromBytes(bytes),
            as: .description
        )
    }

    internal func test_ToSolidityAddress() {
        SnapshotTesting.assertSnapshot(
            of: try AccountId(num: 5005).toSolidityAddress(),
            as: .lines
        )
    }

    internal func test_FromEvmAddress() {
        SnapshotTesting.assertSnapshot(
            of: try AccountId(
                evmAddress: .fromString("0x302a300506032b6570032100114e6abc371b82da"), shard: 0, realm: 0),
            as: .description
        )
    }

    internal func test_FromEvmAddressWithPrefix() throws {
        let evmAddressString = "0x302a300506032b6570032100114e6abc371b82da"
        let evmAddress = try EvmAddress.fromString(evmAddressString)
        let id1 = try AccountId.fromEvmAddress(evmAddress, shard: 0, realm: 0)
        let id2 = try AccountId.fromEvmAddress(evmAddressString, shard: 0, realm: 0)

        XCTAssertEqual(id1, id2)
    }

    internal func test_FromEvmAddressWithShardAndRealm() throws {
        let evmAddressString = "0x302a300506032b6570032100114e6abc371b82da"
        let evmAddress = try EvmAddress.fromString(evmAddressString)
        let id1 = AccountId.init(evmAddress: evmAddress, shard: 1, realm: 2)
        let id2 = try AccountId.fromEvmAddress(evmAddressString, shard: 1, realm: 2)

        XCTAssertEqual(id1, id2)
    }

    internal func test_ToEvmAddressWithShardAndRealm() throws {
        let evmAddressString = "0x00000000000000000000000000000000000004d2"
        let id1 = AccountId.init(evmAddress: try EvmAddress.fromString(evmAddressString), shard: 1, realm: 2)
        let id2 = try AccountId.fromEvmAddress(evmAddressString, shard: 1, realm: 2)

        XCTAssertEqual(try id1.toEvmAddress().toString(), evmAddressString)
        XCTAssertEqual(try id2.toEvmAddress().toString(), evmAddressString)
    }
}
