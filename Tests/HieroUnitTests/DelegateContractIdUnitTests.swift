// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class DelegateContractIdUnitTests: HieroUnitTestCase {
    internal func test_FromString() throws {
        SnapshotTesting.assertSnapshot(of: try DelegateContractId.fromString("0.0.5005"), as: .description)
    }

    internal func test_FromSolidityAddress() throws {
        SnapshotTesting.assertSnapshot(
            of: try DelegateContractId.fromSolidityAddress("000000000000000000000000000000000000138D"),
            as: .description)
    }

    internal func test_FromSolidityAddressWith0x() throws {
        SnapshotTesting.assertSnapshot(
            of: try DelegateContractId.fromSolidityAddress("0x000000000000000000000000000000000000138D"),
            as: .description)
    }

    internal func test_ToBytes() throws {
        SnapshotTesting.assertSnapshot(
            of: try DelegateContractId.fromString("0.0.5005").toBytes().hexStringEncoded(), as: .description)
    }

    internal func test_FromBytes() throws {
        SnapshotTesting.assertSnapshot(
            of: try DelegateContractId.fromBytes(DelegateContractId.fromString("0.0.5005").toBytes()),
            as: .description)
    }

    internal func test_ToSolidityAddress() throws {
        SnapshotTesting.assertSnapshot(of: try DelegateContractId(5005).toSolidityAddress(), as: .description)
    }
}
