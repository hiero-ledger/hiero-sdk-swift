/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import Hiero
import XCTest

internal final class ContractBytecode: XCTestCase {
    internal func testQuery() async throws {
        let testEnv = try TestEnvironment.nonFree

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

        let bytecode = try await ContractBytecodeQuery()
            .contractId(contractId)
            .execute(testEnv.client)

        XCTAssertEqual(bytecode.count, 798)

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

    internal func testGetCostBigMaxQuery() async throws {
        let testEnv = try TestEnvironment.nonFree

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

        let bytecodeQuery = ContractBytecodeQuery()
            .contractId(contractId)
            .maxPaymentAmount(Hbar(1000))

        let cost = try await bytecodeQuery.getCost(testEnv.client)

        let bytecode = try await bytecodeQuery.paymentAmount(cost).execute(testEnv.client)

        XCTAssertEqual(bytecode.count, 798)

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

    internal func testGetCostSmallMaxQuery() async throws {
        let testEnv = try TestEnvironment.nonFree

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

        let bytecodeQuery = ContractBytecodeQuery()
            .contractId(contractId)
            .maxPaymentAmount(Hbar.fromTinybars(1))

        let cost = try await bytecodeQuery.getCost(testEnv.client)

        await assertThrowsHErrorAsync(
            try await bytecodeQuery.execute(testEnv.client),
            "expected error querying contract bytecode"
        ) { error in
            // note: there's a very small chance this fails if the cost of a AccountInfoQuery changes right when we execute it.
            XCTAssertEqual(error.kind, .maxQueryPaymentExceeded(queryCost: cost, maxQueryPayment: .fromTinybars(1)))
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
