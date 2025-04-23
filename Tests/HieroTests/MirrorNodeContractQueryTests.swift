// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class MirrorNodeContractQueryTests: XCTestCase {
    private static let contractId: ContractID = ContractId(1,2,3)
    private static let evmAddress: String = EvmAddress.fromString("0x1234567890abcdef1234567890abcdef12345")
    private static let sender: AccountId = AccountId(1,2,3)
    private static let expirationTime = Timestamp(seconds: 1_554_158_728, subSecondNanos: 0)
    private static let keys: KeyList = [.single(Resources.publicKey)]
    private static let fileMemo = "Hello memo"

    internal func testGetSetContractId() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.contractId, ContractId())

        query.contents(Self.contractId)

        XCTAssertEqual(query.contractId, Self.contractId)
    }

    internal func testGetSetContractEvmAddress() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.contractEvmAddress, EvmAddress())

        query.contents(Self.evmAddress)

        XCTAssertEqual(query.contractEvmAddress, Self.evmAddress)
    }

    internal func testGetSetSender() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.sender, AccountId())

        query.contents(Self.sender)

        XCTAssertEqual(query.sender, Self.sender)
    }

    internal func testSetFunction() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.senderEvmAddress, EvmAddress())

        query.contents(Self.evmAddress)

        XCTAssertEqual(query.senderEvmAddress, Self.evmAddress)
    }
}
