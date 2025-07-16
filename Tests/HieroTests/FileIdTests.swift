// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class FileIdTests: XCTestCase {
    internal func testFromString() {
        XCTAssertEqual(try FileId.fromString("0.0.5005"), FileId(num: 5005))
    }

    internal func testToFromBytes() {
        let a: FileId = "0.0.5005"
        XCTAssertEqual(a, try FileId.fromBytes(a.toBytes()))
        let b: FileId = "1.2.5005"
        XCTAssertEqual(b, try FileId.fromBytes(b.toBytes()))
    }

    internal func testFromSolidarityAddress() {
        assertSnapshot(
            of: try FileId.fromSolidityAddress("000000000000000000000000000000000000138D"), as: .description)
    }

    internal func testToSolidityAddress() {
        assertSnapshot(of: try FileId(5005).toSolidityAddress(), as: .lines)
    }

    internal func testGetAddressBook() {
        assertSnapshot(of: FileId.getAddressBookFileIdFor(shard: 1, realm: 2), as: .description)
    }

    internal func testGetFeeSchedule() {
        assertSnapshot(of: FileId.getFeeScheduleFileIdFor(shard: 1, realm: 2), as: .description)
    }

    internal func testGetExchangeRates() {
        assertSnapshot(of: FileId.getExchangeRatesFileIdFor(shard: 1, realm: 2), as: .description)
    }

    internal func testFromEvmAddressWithPrefix() throws {
        let evmAddressString = "0x302a300506032b6570032100114e6abc371b82da"
        let evmAddress = try EvmAddress.fromString(evmAddressString)
        let id1 = try FileId.fromEvmAddress(evmAddress, shard: 0, realm: 0)
        let id2 = try FileId.fromEvmAddress(evmAddressString, shard: 0, realm: 0)

        XCTAssertEqual(id1, id2)
    }

    internal func testFromEvmAddressWithShardAndRealm() throws {
        let evmAddressString = "0x302a300506032b6570032100114e6abc371b82da"
        let evmAddress = try EvmAddress.fromString(evmAddressString)
        let id1 = FileId.init(evmAddress: evmAddress, shard: 1, realm: 2)
        let id2 = try FileId.fromEvmAddress(evmAddressString, shard: 1, realm: 2)

        XCTAssertEqual(id1, id2)
    }

    internal func testToEvmAddressWithShardAndRealm() throws {
        let evmAddressString = "0x00000000000000000000000000000000000004d2"
        let id1 = FileId.init(evmAddress: try EvmAddress.fromString(evmAddressString), shard: 1, realm: 2)
        let id2 = try FileId.fromEvmAddress(evmAddressString, shard: 1, realm: 2)

        XCTAssertEqual(try id1.toEvmAddress().toString(), evmAddressString)
        XCTAssertEqual(try id2.toEvmAddress().toString(), evmAddressString)
    }
}
