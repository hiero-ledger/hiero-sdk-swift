// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import Hiero
import HieroProtobufs

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
        protoSpec.contractID = testContractId.toProtobuf()

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
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoSpec.contractID.shardNum),  testContractId.shard)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoSpec.contractID.realmNum),  testContractId.realm)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoSpec.contractID.contractNum), testContractId.num)
    }
}
