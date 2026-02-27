// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import XCTest

@testable import Hiero

final class HookEntityIdUnitTests: XCTestCase {

    private let testAccountId = AccountId(shard: 1, realm: 2, num: 3)
    private let testContractId = ContractId(shard: 4, realm: 5, num: 6)

    func test_GetSetAccountId() {
        var hookEntityId = HookEntityId()

        hookEntityId.accountId(testAccountId)

        XCTAssertEqual(hookEntityId.accountId, testAccountId)
        XCTAssertNil(hookEntityId.contractId)
    }

    func test_GetSetContractId() {
        var hookEntityId = HookEntityId()

        hookEntityId.contractId(testContractId)

        XCTAssertEqual(hookEntityId.contractId, testContractId)
        XCTAssertNil(hookEntityId.accountId)
    }

    func test_SetAccountIdResetsContractId() {
        var hookEntityId = HookEntityId()

        hookEntityId.contractId(testContractId)
        hookEntityId.accountId(testAccountId)

        XCTAssertEqual(hookEntityId.accountId, testAccountId)
        XCTAssertNil(hookEntityId.contractId)
    }

    func test_SetContractIdResetsAccountId() {
        var hookEntityId = HookEntityId()

        hookEntityId.accountId(testAccountId)
        hookEntityId.contractId(testContractId)

        XCTAssertEqual(hookEntityId.contractId, testContractId)
        XCTAssertNil(hookEntityId.accountId)
    }

    func test_FromProtobufAccountId() throws {
        var protoMsg = Proto_HookEntityId()
        protoMsg.entityID = .accountID(testAccountId.toProtobuf())

        let hookEntityId = try HookEntityId.fromProtobuf(protoMsg)

        XCTAssertEqual(hookEntityId.accountId, testAccountId)
        XCTAssertNil(hookEntityId.contractId)
    }

    func test_FromProtobufContractId() throws {
        var protoMsg = Proto_HookEntityId()
        protoMsg.entityID = .contractID(testContractId.toProtobuf())

        let hookEntityId = try HookEntityId.fromProtobuf(protoMsg)

        XCTAssertEqual(hookEntityId.contractId, testContractId)
        XCTAssertNil(hookEntityId.accountId)
    }

    func test_ToProtobufAccountId() {
        let hookEntityId = HookEntityId(accountId: testAccountId)

        let protoMsg = hookEntityId.toProtobuf()

        guard case .accountID(let protoAccountId) = protoMsg.entityID else {
            XCTFail("Expected entityID to be .accountID")
            return
        }
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoAccountId.shardNum), testAccountId.shard)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoAccountId.realmNum), testAccountId.realm)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoAccountId.accountNum), testAccountId.num)
    }

    func test_ToProtobufContractId() {
        let hookEntityId = HookEntityId(contractId: testContractId)

        let protoMsg = hookEntityId.toProtobuf()

        guard case .contractID(let protoContractId) = protoMsg.entityID else {
            XCTFail("Expected entityID to be .contractID")
            return
        }
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoContractId.shardNum), testContractId.shard)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoContractId.realmNum), testContractId.realm)
        XCTAssertEqual(UInt64(truncatingIfNeeded: protoContractId.contractNum), testContractId.num)
    }
}
