import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ContractIdTests: XCTestCase {
    internal func testParse() {
        assertSnapshot(of: try ContractId.fromString("0.0.5005"), as: .description)
    }

    internal func testFromSolidityAddress() {
        assertSnapshot(
            of: try ContractId.fromSolidityAddress("000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testFromSolidityAddress0x() {
        assertSnapshot(
            of: try ContractId.fromSolidityAddress("0x000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testFromEvmAddress() {
        assertSnapshot(
            of: try ContractId.fromEvmAddress(1, 2, "000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testFromEvmAddress0x() {
        assertSnapshot(
            of: try ContractId.fromEvmAddress(1, 2, "0x000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testParseEvmAddress() {
        assertSnapshot(
            of: try ContractId.fromString("1.2.98329e006610472e6b372c080833f6d79ed833cf"),
            as: .description
        )
    }

    internal func testToFromBytes() {
        let a: ContractId = "1.2.3"
        XCTAssertEqual(a, try .fromBytes(a.toBytes()))
        let b: ContractId = "1.2.0x98329e006610472e6B372C080833f6D79ED833cf"
        XCTAssertEqual(b, try .fromBytes(b.toBytes()))
    }

    internal func testToSolidityAddress() {
        assertSnapshot(of: try ContractId(num: 5005).toSolidityAddress(), as: .lines)
    }

    internal func testToSolidityAddress2() {
        assertSnapshot(
            of: try ContractId.fromEvmAddress(1, 2, "0x98329e006610472e6B372C080833f6D79ED833cf")
                .toSolidityAddress(),
            as: .lines
        )
    }

    internal func testFromEvmAddressWithPrefix() throws {
        let evmAddressString = "0x302a300506032b6570032100114e6abc371b82da"
        let evmAddress = try EvmAddress.fromString(evmAddressString)
        let id1 = try ContractId.fromEvmAddress(evmAddress, shard: 0, realm: 0)
        let id2 = try ContractId.fromEvmAddress(evmAddressString, shard: 0, realm: 0)

        XCTAssertEqual(id1, id2)
    }

    internal func testFromEvmAddressWithShardAndRealm() throws {
        let evmAddressString = "0x302a300506032b6570032100114e6abc371b82da"
        let evmAddress = try EvmAddress.fromString(evmAddressString)
        let id1 = ContractId.init(evmAddress: evmAddress, shard: 1, realm: 2)
        let id2 = try ContractId.fromEvmAddress(evmAddressString, shard: 1, realm: 2)

        XCTAssertEqual(id1, id2)
    }

    internal func testToEvmAddressWithShardAndRealm() throws {
        let evmAddressString = "0x00000000000000000000000000000000000004d2"
        let id1 = ContractId.init(evmAddress: try EvmAddress.fromString(evmAddressString), shard: 1, realm: 2)
        let id2 = try ContractId.fromEvmAddress(evmAddressString, shard: 1, realm: 2)

        XCTAssertEqual(try id1.toEvmAddress().toString(), evmAddressString)
        XCTAssertEqual(try id2.toEvmAddress().toString(), evmAddressString)
    }
}
