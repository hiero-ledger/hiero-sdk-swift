// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class MirrorNodeContractQueryTests: XCTestCase {
    private static let contractId: ContractId = ContractId(shard: 1, realm: 2, num: 3)
    private static let evmAddress: String = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"
    private static let sender: AccountId = AccountId(shard: 4, realm: 5, num: 6)
    private static let functionName: String = "transfer"
    private static let value: Int64 = 7
    private static let gasLimit: Int64 = 8
    private static let gasPrice: Int64 = 9
    private static let blockNumber: UInt64 = 10

    internal func testGetSetContractId() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.contractId, nil)

        query.contractId(Self.contractId)

        XCTAssertEqual(query.contractId, Self.contractId)
    }

    internal func testGetSetContractEvmAddress() throws {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.contractEvmAddress, nil)

        query.contractEvmAddress(try EvmAddress.fromString(Self.evmAddress))

        XCTAssertEqual(query.contractEvmAddress?.toString(), Self.evmAddress)
    }

    internal func testGetSetSender() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.sender, nil)

        query.sender(Self.sender)

        XCTAssertEqual(query.sender, Self.sender)
    }

    internal func testGetSetSenderEvmAddress() throws {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.senderEvmAddress, nil)

        query.senderEvmAddress(try EvmAddress.fromString(Self.evmAddress))

        XCTAssertEqual(query.senderEvmAddress?.toString(), Self.evmAddress)
    }

    internal func testSetFunction() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.callData, Data())

        let params: ContractFunctionParameters = ContractFunctionParameters()
        params.addAddress(Self.evmAddress)
        params.addUint64(100)
        query.function(Self.functionName, params)

        XCTAssertEqual(query.callData, params.toBytes(Self.functionName))
    }

    internal func testGetSetValue() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.value, nil)

        query.value(Self.value)

        XCTAssertEqual(query.value, Self.value)
    }

    internal func testGetSetGasLimit() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.gasLimit, nil)

        query.gasLimit(Self.gasLimit)

        XCTAssertEqual(query.gasLimit, Self.gasLimit)
    }

    internal func testGetSetGasPrice() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.gasPrice, nil)

        query.gasPrice(Self.gasPrice)

        XCTAssertEqual(query.gasPrice, Self.gasPrice)
    }

    internal func testGetSetBlockNumber() {
        let query = MirrorNodeContractEstimateGasQuery()

        XCTAssertEqual(query.blockNumber, nil)

        query.blockNumber(Self.blockNumber)

        XCTAssertEqual(query.blockNumber, Self.blockNumber)
    }
}
