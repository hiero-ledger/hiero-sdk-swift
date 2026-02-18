// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import XCTest

@testable import Hiero

final class EvmHookSpecUnitTests: XCTestCase {

    private let testContractId = ContractId(shard: 1, realm: 2, num: 3)

    func test_GetSetContractId() {
        // Given
        var evmHookSpec = EvmHookSpec()

        // When
        evmHookSpec.contractId = testContractId

        // Then
        XCTAssertEqual(evmHookSpec.contractId, testContractId)
    }

    // TEST_F(EvmHookSpecUnitTests, FromProtobuf)
    func test_FromProtobuf() throws {
        // Given
        var protoSpec = Com_Hedera_Hapi_Node_Hooks_EvmHookSpec()
        protoSpec.bytecodeSource = .contractID(testContractId.toProtobuf())

        // When
        let evmHookSpec = try EvmHookSpec.fromProtobuf(protoSpec)

        // Then
        XCTAssertEqual(evmHookSpec.contractId, testContractId)
    }

    func test_ToProtobuf() {
        // Given
        var evmHookSpec = EvmHookSpec()
        evmHookSpec.contractId = testContractId

        // When
        let protoSpec = evmHookSpec.toProtobuf()

        // Then
        guard case .contractID(let contractID)? = protoSpec.bytecodeSource else {
            XCTFail("Expected bytecodeSource to be .contractID")
            return
        }
        XCTAssertEqual(UInt64(truncatingIfNeeded: contractID.shardNum), testContractId.shard)
        XCTAssertEqual(UInt64(truncatingIfNeeded: contractID.realmNum), testContractId.realm)
        XCTAssertEqual(UInt64(truncatingIfNeeded: contractID.contractNum), testContractId.num)
    }
}
