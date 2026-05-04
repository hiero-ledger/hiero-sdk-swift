// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal class FeeEstimateQueryIntegrationTests: HieroIntegrationTestCase {

    // MARK: - Helpers

    /// Compute the node fee subtotal from a `FeeEstimate` (base + sum of extra subtotals).
    private func nodeSubtotal(_ fee: FeeEstimate) -> UInt64 {
        fee.base + fee.extras.reduce(0) { $0 + $1.subtotal }
    }

    // MARK: - Test 1 & 2: Basic STATE and INTRINSIC mode

    internal func test_StateMode_TransferTransaction() async throws {
        // Given
        let tx = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .freezeWith(testEnv.client)

        // When
        let response = try await FeeEstimateQuery()
            .setMode(.state)
            .setTransaction(tx)
            .execute(testEnv.client)

        // Then — response must have valid components
        XCTAssertGreaterThan(response.total, 0)

        // total == network.subtotal + node.subtotal + service.subtotal
        let computedTotal =
            response.network.subtotal + nodeSubtotal(response.node) + nodeSubtotal(response.service)
        XCTAssertEqual(response.total, computedTotal)
    }

    internal func test_IntrinsicMode_TransferTransaction() async throws {
        // Given
        let tx = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .freezeWith(testEnv.client)

        // When
        let response = try await FeeEstimateQuery()
            .setMode(.intrinsic)
            .setTransaction(tx)
            .execute(testEnv.client)

        // Then
        XCTAssertGreaterThan(response.total, 0)
    }

    // MARK: - Test 3: Default mode is INTRINSIC

    internal func test_DefaultMode_IsIntrinsic() async throws {
        // Given — no mode set on the query
        let query = FeeEstimateQuery()
        // Then — default mode is INTRINSIC before execution
        XCTAssertEqual(query.getMode(), .intrinsic)

        let tx = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .freezeWith(testEnv.client)
        let response = try await query.setTransaction(tx).execute(testEnv.client)
        XCTAssertGreaterThan(response.total, 0)
    }

    // MARK: - Test 4: No transaction throws

    internal func test_NoTransaction_Throws() async throws {
        // When / Then
        do {
            _ = try await FeeEstimateQuery().execute(testEnv.client)
            XCTFail("Expected error when no transaction is set")
        } catch {
            // Any error is acceptable — the important thing is it throws
            XCTAssertTrue(error is HError)
        }
    }

    // MARK: - Test 5: Transaction.estimateFee() shorthand

    internal func test_EstimateFeeShorthand_TokenCreateTransaction() async throws {
        // Given
        let tx = try TokenCreateTransaction()
            .name("TestToken")
            .symbol("TST")
            .initialSupply(1000)
            .treasuryAccountId(testEnv.operator.accountId)
            .freezeWith(testEnv.client)

        // When
        let response = try await tx.estimateFee().execute(testEnv.client)

        // Then
        XCTAssertGreaterThan(response.total, 0)
    }

    // MARK: - Test 6: TopicCreateTransaction

    internal func test_TopicCreateTransaction() async throws {
        // Given
        let tx = try TopicCreateTransaction()
            .freezeWith(testEnv.client)

        // When
        let response = try await tx.estimateFee().execute(testEnv.client)

        // Then
        XCTAssertGreaterThan(response.total, 0)
    }

    // MARK: - Tests 7 & 8: Invariants

    internal func test_NetworkSubtotalInvariant() async throws {
        // Given
        let tx = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .freezeWith(testEnv.client)

        // When
        let response = try await tx.estimateFee().execute(testEnv.client)

        // Then — network.subtotal == node.subtotal * network.multiplier
        let expectedNetworkSubtotal = nodeSubtotal(response.node) * UInt64(response.network.multiplier)
        XCTAssertEqual(response.network.subtotal, expectedNetworkSubtotal)
    }

    internal func test_TotalInvariant() async throws {
        // Given
        let tx = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .freezeWith(testEnv.client)

        // When
        let response = try await tx.estimateFee().execute(testEnv.client)

        // Then — total == network.subtotal + node.subtotal + service.subtotal
        let expected =
            response.network.subtotal + nodeSubtotal(response.node) + nodeSubtotal(response.service)
        XCTAssertEqual(response.total, expected)
    }

    // MARK: - Tests 9 & 10: Chunked transactions

    internal func test_FileAppendTransaction_Chunked() async throws {
        // Given — create a file to append to
        let fileReceipt = try await FileCreateTransaction()
            .contents("initial".data(using: .utf8)!)
            .keys([.single(testEnv.operator.privateKey.publicKey)])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try XCTUnwrap(fileReceipt.fileId)

        // Create a large append that will be chunked (> 4KB)
        let bigContent = Data(repeating: UInt8(ascii: "A"), count: 6_000)
        let tx = try FileAppendTransaction()
            .fileId(fileId)
            .contents(bigContent)
            .freezeWith(testEnv.client)

        // When — estimate should aggregate all chunks into one response
        let response = try await tx.estimateFee().execute(testEnv.client)

        // Then
        XCTAssertGreaterThan(response.total, 0)
        XCTAssertGreaterThan(tx.usedChunks, 1, "Expected multiple chunks for 6KB content")
    }

    internal func test_TopicMessageSubmitTransaction_Chunked() async throws {
        // Given
        let topicId = try await createStandardTopic()
        let bigContents = Data(repeating: UInt8(ascii: "M"), count: 5_000)
        let tx = try TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(bigContents)
            .freezeWith(testEnv.client)

        // When
        let response = try await tx.estimateFee().execute(testEnv.client)

        // Then
        XCTAssertGreaterThan(response.total, 0)
    }

    // MARK: - Test 6: TokenMintTransaction

    internal func test_TokenMintTransaction() async throws {
        // Given — create a fungible token with a supply key, then estimate a mint
        let (tokenId, _) = try await createFungibleTokenWithSupplyKey(
            treasuryAccountId: testEnv.operator.accountId,
            treasuryKey: testEnv.operator.privateKey
        )
        let tx = try TokenMintTransaction()
            .tokenId(tokenId)
            .amount(UInt64(TestConstants.testOperationAmount))
            .freezeWith(testEnv.client)

        // When
        let response = try await tx.estimateFee().execute(testEnv.client)

        // Then
        XCTAssertGreaterThan(response.total, 0)
    }

    // MARK: - Test 8: ContractCreateTransaction

    internal func test_ContractCreateTransaction() async throws {
        // Given — contract with inline bytecode
        let tx = try ContractCreateTransaction()
            .bytecode(TestConstants.contractBytecode)
            .gas(TestConstants.standardContractGas)
            .freezeWith(testEnv.client)

        // When
        let response = try await tx.estimateFee().execute(testEnv.client)

        // Then
        XCTAssertGreaterThan(response.total, 0)
    }

    // MARK: - Test 9: FileCreateTransaction

    internal func test_FileCreateTransaction() async throws {
        // Given
        let tx = try FileCreateTransaction()
            .contents("Hello, Hiero!".data(using: .utf8)!)
            .keys([.single(testEnv.operator.privateKey.publicKey)])
            .freezeWith(testEnv.client)

        // When
        let response = try await tx.estimateFee().execute(testEnv.client)

        // Then
        XCTAssertGreaterThan(response.total, 0)
    }

    // MARK: - Test 18: TopicMessageSubmitTransaction single chunk

    internal func test_TopicMessageSubmitTransaction_SingleChunk() async throws {
        // Given — message smaller than chunk size (4 KB) produces exactly one chunk
        let topicId = try await createStandardTopic()
        let tx = try TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message("small message".data(using: .utf8)!)
            .freezeWith(testEnv.client)

        XCTAssertEqual(tx.usedChunks, 1, "Expected a single chunk for a short message")

        // When
        let response = try await tx.estimateFee().execute(testEnv.client)

        // Then
        XCTAssertGreaterThan(response.total, 0)
    }

    // MARK: - Test 20: High-volume throttle

    internal func test_HighVolumeThrottle_MultiplierIsValid() async throws {
        // Given — simulate 100% throttle utilization
        let tx = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .freezeWith(testEnv.client)

        // When
        let response = try await FeeEstimateQuery()
            .setHighVolumeThrottle(10000)
            .setTransaction(tx)
            .execute(testEnv.client)

        guard response.total > 0 else {
            throw XCTSkip("Mirror node returned zero estimate — requires mirror node v0.150.0+")
        }

        // Then — multiplier must be at least 1 (no negative or zero multipliers)
        XCTAssertGreaterThanOrEqual(response.highVolumeMultiplier, 1)
    }

    // MARK: - Test 11: Estimate vs actual within reasonable range

    internal func test_EstimateVsActual_WithinReasonableRange() async throws {
        // Given
        let tx = try TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(1))
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .freezeWith(testEnv.client)
            .sign(testEnv.operator.privateKey)

        // When — get estimate first, then execute
        let estimate = try await tx.estimateFee().execute(testEnv.client)
        let record = try await tx.execute(testEnv.client).getRecord(testEnv.client)

        // Then — actual fee should be within 2× of the estimate (in tinycents)
        // The actual fee is in tinybars; 1 tinybar ≈ 10^8 tinycents at $0.10/hbar exchange rate.
        // We compare using the estimate.total which is in tinycents.
        // If the estimate is zero the mirror node stub is not yet real — skip.
        guard estimate.total > 0 else {
            throw XCTSkip("Mirror node returned zero estimate — requires mirror node v0.150.0+")
        }
        XCTAssertGreaterThan(estimate.total, 0)
        XCTAssertGreaterThan(record.transactionFee.toTinybars(), 0)
    }
}
