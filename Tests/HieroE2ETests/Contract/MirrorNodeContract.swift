// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class MirrorNodeContract: XCTestCase {
    internal func testCanEstimateAndCall() async throws {
        let testEnv = try TestEnvironment.global

        let fileCreateReceipt = try await FileCreateTransaction()
            .keys([.single(testEnv.operator.privateKey.publicKey)])
            .contents(ContractHelpers.bytecode)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try XCTUnwrap(fileCreateReceipt.fileId)

        let receipt = try await ContractCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .gas(200000)
            .constructorParameters(ContractFunctionParameters().addString("Hello from Hiero."))
            .bytecodeFileId(fileId)
            .contractMemo("[e2e::ContractCreateTransaction]")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let contractId = try XCTUnwrap(receipt.contractId)

        /// Wait 3 seconds for the mirror node to import the contract data.
        try await Task.sleep(nanoseconds: 3_000_000_000)

        let estimateResponse = try await MirrorNodeContractEstimateGasQuery()
            .contractId(contractId)
            .sender(testenv.operator.accountId)
            .gasLimit(50_000)
            .gasPrice(1234)
            .function("getMessage")
            .execute(client)

        let estimatedGas = try XCTUnwrap(UInt64(estimateResponse, radix: 16))

        let consensusNodeResponse = try await ContractCallQuery()
            .contractId(contractId)
            .gas(estimatedGas)
            .maxPaymentAmount(Hbar(1))
            .function("getMessage")
            .execute(client)

        let mirrorNodeResponse = try await MirrorNodeContractCallQuery()
            .contractId(contractId)
            .function("getMessage")
            .execute(client)

        XCTAssertEqual(consensusNodeResponse.bytes.map { String(format: "%02x", $0) }.joined(), mirrorNodeResponse)

        addTeardownBlock {
            _ = try await ContractDeleteTransaction(contractId: contractId)
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)

            _ = try await FileDeleteTransaction(fileId: fileId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }
    }

    internal func testBadContractId() async throws {
        let testEnv = try TestEnvironment.global

        let contractId = ContractId(999999)

        await assertThrowsHErrorAsync(
            try await MirrorNodeContractEstimateGasQuery()
                .contractId(contractId)
                .function("getMessage")
                .execute(testEnv.client),
            "expected error querying gas estimate"
        ) { error in
            XCTAssertEqual(error.kind, .basicParse)
        }
    }

    internal func testLowGasLimit() async throws {
        let testEnv = try TestEnvironment.global

        let fileCreateReceipt = try await FileCreateTransaction()
            .keys([.single(testEnv.operator.privateKey.publicKey)])
            .contents(ContractHelpers.bytecode)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try XCTUnwrap(fileCreateReceipt.fileId)

        let receipt = try await ContractCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .gas(200000)
            .constructorParameters(ContractFunctionParameters().addString("Hello from Hiero."))
            .bytecodeFileId(fileId)
            .contractMemo("[e2e::ContractCreateTransaction]")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let contractId = try XCTUnwrap(receipt.contractId)

        /// Wait 3 seconds for the mirror node to import the contract data.
        try await Task.sleep(nanoseconds: 3_000_000_000)

        await assertThrowsHErrorAsync(
            try await MirrorNodeContractEstimateGasQuery()
                .contractId(contractId)
                .sender(testEnv.operator?.accountId)
                .gasLimit(10)
                .gasPrice(1234)
                .function("getMessage")
                .execute(testEnv.client),
            "expected error querying gas estimate"
        ) { error in
            XCTAssertEqual(error.kind, .basicParse)
        }

        addTeardownBlock {
            _ = try await ContractDeleteTransaction(contractId: contractId)
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)

            _ = try await FileDeleteTransaction(fileId: fileId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }
    }
}
