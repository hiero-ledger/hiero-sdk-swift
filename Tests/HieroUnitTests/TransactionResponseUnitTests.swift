// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TransactionResponseUnitTests: HieroUnitTestCase {
    private let submittingNode = AccountId(num: 5006)
    private let otherNode = AccountId(num: 5005)
    private let thirdNode = AccountId(num: 5007)

    private func makeClient() throws -> Client {
        try Client.forNetwork([
            "127.0.0.1:50211": otherNode,
            "127.0.0.1:50212": submittingNode,
            "127.0.0.1:50213": thirdNode,
        ])
    }

    private func makeResponse(transactionNodeAccountIds: [AccountId]? = nil) -> TransactionResponse {
        TransactionResponse(
            nodeAccountId: submittingNode,
            transactionId: TestConstants.transactionId,
            transactionHash: TransactionHash(hashing: Data([1, 2, 3])),
            transactionNodeAccountIds: transactionNodeAccountIds
        )
    }

    internal func test_GetReceiptAndRecordQueriesArePinnedByDefault() throws {
        let client = try makeClient()
        let response = makeResponse(transactionNodeAccountIds: [otherNode, submittingNode, thirdNode])

        XCTAssertEqual(response.getReceiptQuery(client).nodeAccountIds, [submittingNode])
        XCTAssertEqual(response.getRecordQuery(client).nodeAccountIds, [submittingNode])
    }

    internal func test_GetReceiptAndRecordQueriesArePinnedWithoutClient() throws {
        let client = try makeClient()
        client.allowReceiptNodeFailover = true
        let response = makeResponse(transactionNodeAccountIds: [otherNode, submittingNode, thirdNode])

        XCTAssertEqual(response.getReceiptQuery().nodeAccountIds, [submittingNode])
        XCTAssertEqual(response.getRecordQuery().nodeAccountIds, [submittingNode])
    }

    internal func test_GetReceiptAndRecordQueriesUseExplicitTransactionNodesWhenFailoverEnabled() throws {
        let client = try makeClient()
        client.allowReceiptNodeFailover = true
        let response = makeResponse(transactionNodeAccountIds: [otherNode, submittingNode, thirdNode, otherNode])

        XCTAssertEqual(response.getReceiptQuery(client).nodeAccountIds, [submittingNode, otherNode, thirdNode])
        XCTAssertEqual(response.getRecordQuery(client).nodeAccountIds, [submittingNode, otherNode, thirdNode])
    }

    internal func test_GetReceiptAndRecordQueriesUseClientNetworkWhenFailoverEnabledWithoutExplicitNodes() throws {
        let client = try makeClient()
        client.allowReceiptNodeFailover = true
        let response = makeResponse()

        let expected = uniqueNodeAccountIds([submittingNode] + client.consensus.nodes)

        XCTAssertEqual(response.getReceiptQuery(client).nodeAccountIds, expected)
        XCTAssertEqual(response.getRecordQuery(client).nodeAccountIds, expected)
    }

    internal func test_TransactionResponseKeepsExplicitTransactionNodes() throws {
        let client = try makeClient()
        client.allowReceiptNodeFailover = true
        let transaction = Transaction().nodeAccountIds([otherNode, submittingNode])

        let response = transaction.makeResponse(
            Proto_TransactionResponse(),
            TransactionHash(hashing: Data([4, 5, 6])),
            submittingNode,
            TestConstants.transactionId
        )

        XCTAssertEqual(response.getReceiptQuery(client).nodeAccountIds, [submittingNode, otherNode])
    }

    internal func test_TransactionResponseFallsBackToClientNetworkWithoutExplicitTransactionNodes() throws {
        let client = try makeClient()
        client.allowReceiptNodeFailover = true
        let transaction = Transaction()

        let response = transaction.makeResponse(
            Proto_TransactionResponse(),
            TransactionHash(hashing: Data([4, 5, 6])),
            submittingNode,
            TestConstants.transactionId
        )

        XCTAssertEqual(
            response.getReceiptQuery(client).nodeAccountIds,
            uniqueNodeAccountIds([submittingNode] + client.consensus.nodes)
        )
    }

    private func uniqueNodeAccountIds(_ nodeAccountIds: [AccountId]) -> [AccountId] {
        var seen: Set<AccountId> = []
        var result: [AccountId] = []

        for nodeAccountId in nodeAccountIds where seen.insert(nodeAccountId).inserted {
            result.append(nodeAccountId)
        }

        return result
    }
}
