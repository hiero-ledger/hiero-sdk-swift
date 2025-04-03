// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class DelegateContractIdTests: XCTestCase {
    internal func testFromString() throws {
        assertSnapshot(matching: try DelegateContractId.fromString("0.0.5005"), as: .description)
    }

    internal func testFromSolidityAddress() throws {
        assertSnapshot(
            matching: try DelegateContractId.fromSolidityAddress("000000000000000000000000000000000000138D"),
            as: .description)
    }

    internal func testFromSolidityAddressWith0x() throws {
        assertSnapshot(
            matching: try DelegateContractId.fromSolidityAddress("0x000000000000000000000000000000000000138D"),
            as: .description)
    }

    internal func testToBytes() throws {
        assertSnapshot(
            matching: try DelegateContractId.fromString("0.0.5005").toBytes().hexStringEncoded(), as: .description)
    }

    internal func testFromBytes() throws {
        assertSnapshot(
            matching: try DelegateContractId.fromBytes(DelegateContractId.fromString("0.0.5005").toBytes()),
            as: .description)
    }

    internal func testToSolidityAddress() throws {
        assertSnapshot(matching: try DelegateContractId(5005).toSolidityAddress(), as: .description)
    }
}
