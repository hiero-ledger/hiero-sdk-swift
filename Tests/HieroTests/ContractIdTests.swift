import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ContractIdTests: XCTestCase {
    internal func testParse() {
        assertSnapshot(matching: try ContractId.fromString("0.0.5005"), as: .description)
    }

    internal func testFromSolidityAddress() {
        assertSnapshot(
            matching: try ContractId.fromSolidityAddress("000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testFromSolidityAddress0x() {
        assertSnapshot(
            matching: try ContractId.fromSolidityAddress("0x000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testFromEvmAddress() {
        assertSnapshot(
            matching: try ContractId.fromEvmAddress(1, 2, "000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testFromEvmAddress0x() {
        assertSnapshot(
            matching: try ContractId.fromEvmAddress(1, 2, "0x000000000000000000000000000000000000138D"),
            as: .description
        )
    }

    internal func testParseEvmAddress() {
        assertSnapshot(
            matching: try ContractId.fromString("1.2.98329e006610472e6b372c080833f6d79ed833cf"),
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
        assertSnapshot(matching: try ContractId(num: 5005).toSolidityAddress(), as: .lines)
    }

    internal func testToSolidityAddress2() {
        assertSnapshot(
            matching: try ContractId.fromEvmAddress(1, 2, "0x98329e006610472e6B372C080833f6D79ED833cf")
                .toSolidityAddress(),
            as: .lines
        )
    }
}
