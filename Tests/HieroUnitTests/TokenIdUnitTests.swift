// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenIdUnitTests: HieroUnitTestCase {
    internal func test_FromString() {
        XCTAssertEqual(try TokenId.fromString("0.0.5005"), TokenId(num: 5005))
    }

    internal func test_ToFromBytes() {
        let a: TokenId = "0.0.5005"
        XCTAssertEqual(a, try TokenId.fromBytes(a.toBytes()))
        let b: TokenId = "1.2.5005"
        XCTAssertEqual(b, try TokenId.fromBytes(b.toBytes()))
    }

    internal func test_FromSolidityAddress() {
        SnapshotTesting.assertSnapshot(
            of: try TokenId.fromSolidityAddress("000000000000000000000000000000000000138d"), as: .description)
    }

    internal func test_ToSolidityAddress() {
        SnapshotTesting.assertSnapshot(of: try TokenId(5005).toSolidityAddress(), as: .lines)
    }

    internal func test_FromEvmAddressWithPrefix() throws {
        let evmAddressString = "0x302a300506032b6570032100114e6abc371b82da"
        let evmAddress = try EvmAddress.fromString(evmAddressString)
        let id1 = try TokenId.fromEvmAddress(evmAddress, shard: 0, realm: 0)
        let id2 = try TokenId.fromEvmAddress(evmAddressString, shard: 0, realm: 0)

        XCTAssertEqual(id1, id2)
    }

    internal func test_FromEvmAddressWithShardAndRealm() throws {
        let evmAddressString = "0x302a300506032b6570032100114e6abc371b82da"
        let evmAddress: EvmAddress = try EvmAddress.fromString(evmAddressString)
        let id1 = TokenId.init(evmAddress: evmAddress, shard: 1, realm: 2)
        let id2 = try TokenId.fromEvmAddress(evmAddressString, shard: 1, realm: 2)

        XCTAssertEqual(id1, id2)
    }

    internal func test_ToEvmAddressWithShardAndRealm() throws {
        let evmAddressString = "0x00000000000000000000000000000000000004d2"
        let id1 = TokenId.init(evmAddress: try EvmAddress.fromString(evmAddressString), shard: 1, realm: 2)
        let id2 = try TokenId.fromEvmAddress(evmAddressString, shard: 1, realm: 2)

        XCTAssertEqual(try id1.toEvmAddress().toString(), evmAddressString)
        XCTAssertEqual(try id2.toEvmAddress().toString(), evmAddressString)
    }
}
