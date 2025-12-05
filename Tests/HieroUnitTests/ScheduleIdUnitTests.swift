// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ScheduleIdUnitTests: HieroUnitTestCase {
    internal func test_Parse() {
        XCTAssertEqual(try ScheduleId.fromString("0.0.1001"), ScheduleId(num: 1001))
    }

    internal func test_ToFromBytesRoundtrip() {
        let scheduleId = ScheduleId(num: 1001)

        XCTAssertEqual(scheduleId, try ScheduleId.fromBytes(scheduleId.toBytes()))
    }

    internal func test_GoodChecksumOnMainnet() throws {
        let scheduleId = try ScheduleId.fromString("0.0.123-vfmkw")
        try scheduleId.validateChecksums(on: .mainnet)
    }

    internal func test_GoodChecksumOnTestnet() throws {
        let scheduleId = try ScheduleId.fromString("0.0.123-esxsf")
        try scheduleId.validateChecksums(on: .testnet)
    }

    internal func test_GoodChecksumOnPreviewnet() throws {
        let scheduleId = try ScheduleId.fromString("0.0.123-ogizo")
        try scheduleId.validateChecksums(on: .previewnet)
    }

    internal func test_ToStringWithChecksum() {
        let client = Client.forTestnet()

        XCTAssertEqual(
            "0.0.123-esxsf",
            try ScheduleId.fromString("0.0.123").toStringWithChecksum(client)
        )
    }

    internal func test_BadChecksumOnPreviewnet() throws {
        let scheduleId = try ScheduleId.fromString("0.0.123-ntjli")

        XCTAssertThrowsError(try scheduleId.validateChecksums(on: .previewnet))
    }

    internal func test_MalformedIdFails() {
        XCTAssertThrowsError(try ScheduleId.fromString("0.0."))
    }

    internal func test_MalformedChecksum() {
        XCTAssertThrowsError(try ScheduleId.fromString("0.0.123-ntjl"))
    }

    internal func test_MalformedChecksum2() {
        XCTAssertThrowsError(try ScheduleId.fromString("0.0.123-ntjl1"))
    }

    internal func test_MalformedAlias() {
        XCTAssertThrowsError(
            try ScheduleId.fromString(
                "0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf777"))
    }
    internal func test_MalformedAlias2() {
        XCTAssertThrowsError(
            try ScheduleId.fromString(
                "0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf777g"))
    }
    internal func test_MalformedAliasKey3() {
        XCTAssertThrowsError(
            try ScheduleId.fromString(
                "0.0.303a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf7777"))
    }

    internal func test_FromSolidityAddress() {
        SnapshotTesting.assertSnapshot(
            of: try ScheduleId.fromSolidityAddress("000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func test_FromSolidityAddress0x() {
        SnapshotTesting.assertSnapshot(
            of: try ScheduleId.fromSolidityAddress("0x000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func test_FromBytes() {
        SnapshotTesting.assertSnapshot(
            of: try ScheduleId.fromBytes(ScheduleId(num: 5005).toBytes()),
            as: .description
        )
    }

    internal func test_ToSolidityAddress() {
        SnapshotTesting.assertSnapshot(
            of: try ScheduleId(num: 5005).toSolidityAddress(),
            as: .lines
        )
    }
}
