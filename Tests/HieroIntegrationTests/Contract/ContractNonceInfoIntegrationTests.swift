// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ContractNonceInfoIntegrationTests: HieroIntegrationTestCase {
    // Factory contract bytecode that creates another contract (B) in its constructor.
    // This is used to test contract nonce increment behavior.
    // Note: File contents are stored as the hex string (UTF-8/ASCII), matching TestConstants.contractBytecode
    private static let factoryContractBytecode: Data = {
        let hex =
            "6080604052348015600f57600080fd5b50604051601a90603b565b604051809103906000f0801580156035573d6000803e3d6000fd5"
            + "b50506047565b605c8061009483390190565b603f806100556000396000f3fe6080604052600080fdfea2646970667358221220a201"
            + "22cbad3457fedcc0600363d6e895f17048f5caa4afdab9e655123737567d64736f6c634300081200336080604052348015600f57600"
            + "080fd5b50603f80601d6000396000f3fe6080604052600080fdfea264697066735822122053dfd8835e3dc6fedfb8b4806460b9b716"
            + "3f8a7248bac510c6d6808d9da9d6d364736f6c63430008120033"
        return hex.data(using: .utf8)!
    }()

    internal func test_IncrementNonceThroughContractConstructor() async throws {
        // Given
        let fileId = try await createFile(
            FileCreateTransaction()
                .keys([.single(testEnv.operator.privateKey.publicKey)])
                .contents(Self.factoryContractBytecode),
            key: testEnv.operator.privateKey
        )

        // When
        let contractCreateResponse = try await ContractCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .gas(1_000_000)
            .bytecodeFileId(fileId)
            .execute(testEnv.client)

        let contractCreateReceipt = try await contractCreateResponse.getReceipt(testEnv.client)
        let contractId = try XCTUnwrap(contractCreateReceipt.contractId)
        await registerContract(contractId, adminKey: testEnv.operator.privateKey)

        // Then
        let record = try await contractCreateResponse.getRecord(testEnv.client)
        let contractA = try XCTUnwrap(record.receipt.contractId)

        let contractFunctionResult = try XCTUnwrap(record.contractFunctionResult)
        XCTAssertEqual(contractFunctionResult.contractNonces.count, 2)

        let contractANonceInfo = try XCTUnwrap(
            contractFunctionResult.contractNonces.first { $0.contractId == contractA })
        let contractBNonceInfo = try XCTUnwrap(
            contractFunctionResult.contractNonces.first { $0.contractId != contractA })

        // A.nonce = 2 (incremented once for creation, once for deploying B)
        XCTAssertEqual(contractANonceInfo.nonce, 2)
        // B.nonce = 1 (just created)
        XCTAssertEqual(contractBNonceInfo.nonce, 1)
        // signer nonce should only be set for Ethereum transactions
        XCTAssertNil(contractFunctionResult.signerNonce)
    }
}
