// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs
import XCTest

@testable import Hiero

final class EvmHookCallUnitTests: XCTestCase {

    private let testCallData = Data([0x01, 0x23, 0x45])
    private let testGasLimit: UInt64 = 1_000_000

    func test_GetSetCallData() {
        // Given
        var evmHookCall = EvmHookCall()

        // When
        evmHookCall.data = testCallData

        // Then
        XCTAssertEqual(evmHookCall.data, testCallData)
    }

    func test_GetSetGasLimit() {
        // Given
        var evmHookCall = EvmHookCall()

        // When
        evmHookCall.gasLimit = testGasLimit

        // Then
        XCTAssertEqual(evmHookCall.gasLimit, testGasLimit)
    }

    // MARK: - TEST_F(EvmHookCallUnitTests, FromProtobuf)
    func test_FromProtobuf() throws {
        // Given
        var protoMsg = Proto_EvmHookCall()
        protoMsg.data = testCallData
        protoMsg.gasLimit = testGasLimit

        // When
        let evmHookCall = try EvmHookCall.fromProtobuf(protoMsg)

        // Then
        XCTAssertEqual(evmHookCall.data, testCallData)
        XCTAssertEqual(evmHookCall.gasLimit, testGasLimit)
    }

    // MARK: - TEST_F(EvmHookCallUnitTests, ToProtobuf)
    func test_ToProtobuf() {
        // Given
        var evmHookCall = EvmHookCall()
        evmHookCall.data = testCallData
        evmHookCall.gasLimit = testGasLimit

        // When
        let protoMsg = evmHookCall.toProtobuf()

        // Then
        XCTAssertEqual(protoMsg.data, testCallData)
        XCTAssertEqual(protoMsg.gasLimit, testGasLimit)
    }
}
