// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

private let smartContractBytecode =
    "6080604052348015600f57600080fd5b50604051601a90603b565b604051809103906000f0801580156035573d6000803e3d6000fd5b50506047565b605c8061009483390190565b603f806100556000396000f3fe6080604052600080fdfea2646970667358221220a20122cbad3457fedcc0600363d6e895f17048f5caa4afdab9e655123737567d64736f6c634300081200336080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea264697066735822122053dfd8835e3dc6fedfb8b4806460b9b7163f8a7248bac510c6d6808d9da9d6d364736f6c63430008120033"

internal final class ContractNonceInfo: XCTestCase {
    internal func disabledTestIncrementNonceThroughContractConstructor() async throws {
        let testEnv = try TestEnvironment.nonFree

        let file = try await File.forContent(smartContractBytecode.data(using: .utf8)!, testEnv)

        addTeardownBlock {
            try await file.delete(testEnv)
        }

        let response = try await ContractCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .gas(100000)
            .bytecodeFileId(file.fileId)
            .contractMemo("[e2e::ContractADeploysContractBInConstructor]")
            .execute(testEnv.client)

        let record = try await response.getRecord(testEnv.client)
        let contractA = try XCTUnwrap(record.receipt.contractId)

        addTeardownBlock {
            _ = try await ContractDeleteTransaction()
                .transferAccountId(testEnv.operator.accountId)
                .contractId(contractA)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        let contractFunctionResult = try XCTUnwrap(record.contractFunctionResult)
        XCTAssertEqual(contractFunctionResult.contractNonces.count, 2)

        let contractANonceInfo = try XCTUnwrap(
            contractFunctionResult.contractNonces.first { $0.contractId == contractA })
        let contractBNonceInfo = try XCTUnwrap(
            contractFunctionResult.contractNonces.first { $0.contractId != contractA })

        // A.nonce = 2
        XCTAssertEqual(contractANonceInfo.nonce, 2)
        // B.nonce = 1
        XCTAssertEqual(contractBNonceInfo.nonce, 1)
    }
}
