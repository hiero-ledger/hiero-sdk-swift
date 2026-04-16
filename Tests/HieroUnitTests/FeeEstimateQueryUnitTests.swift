// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class FeeEstimateQueryUnitTests: HieroUnitTestCase {

    // MARK: - FeeEstimateMode

    internal func test_DefaultMode() {
        let query = FeeEstimateQuery()
        XCTAssertEqual(query.getMode(), .intrinsic)
    }

    internal func test_SetMode() {
        let query = FeeEstimateQuery()
        query.setMode(.intrinsic)
        XCTAssertEqual(query.getMode(), .intrinsic)
        query.setMode(.state)
        XCTAssertEqual(query.getMode(), .state)
    }

    // MARK: - Transaction getter/setter

    internal func test_SetGetTransaction() throws {
        let tx = TransferTransaction()
        let query = FeeEstimateQuery()
        XCTAssertNil(query.getTransaction())
        query.setTransaction(tx)
        XCTAssertTrue(query.getTransaction() === tx)
    }

    internal func test_EstimateFeeExtension() throws {
        let tx = TransferTransaction()
        let query = tx.estimateFee()
        XCTAssertTrue(query.getTransaction() === tx)
        XCTAssertEqual(query.getMode(), .intrinsic)
    }

    // MARK: - JSON parsing: FeeExtra

    internal func test_JsonParsing_FeeExtra_AllFields() throws {
        let json: [String: Any] = [
            "name": "Signatures",
            "included": 1,
            "count": 3,
            "charged": 2,
            "fee_per_unit": 100_000,
            "subtotal": 200_000,
        ]
        let extra = try FeeExtra.fromJson(json)
        XCTAssertEqual(extra.name, "Signatures")
        XCTAssertEqual(extra.included, 1)
        XCTAssertEqual(extra.count, 3)
        XCTAssertEqual(extra.charged, 2)
        XCTAssertEqual(extra.feePerUnit, 100_000)
        XCTAssertEqual(extra.subtotal, 200_000)
    }

    internal func test_JsonParsing_FeeExtra_MissingFieldsDefaultToZero() throws {
        let extra = try FeeExtra.fromJson([:])
        XCTAssertEqual(extra.name, "")
        XCTAssertEqual(extra.included, 0)
        XCTAssertEqual(extra.count, 0)
        XCTAssertEqual(extra.charged, 0)
        XCTAssertEqual(extra.feePerUnit, 0)
        XCTAssertEqual(extra.subtotal, 0)
    }

    // MARK: - JSON parsing: FeeEstimate

    internal func test_JsonParsing_FeeEstimate() throws {
        let json: [String: Any] = [
            "base": 500_000,
            "extras": [
                [
                    "name": "Bytes",
                    "included": 1024,
                    "count": 150,
                    "charged": 0,
                    "fee_per_unit": 10_000,
                    "subtotal": 0,
                ] as [String: Any]
            ],
        ]
        let estimate = try FeeEstimate.fromJson(json)
        XCTAssertEqual(estimate.base, 500_000)
        XCTAssertEqual(estimate.extras.count, 1)
        XCTAssertEqual(estimate.extras[0].name, "Bytes")
        XCTAssertEqual(estimate.extras[0].included, 1024)
    }

    internal func test_JsonParsing_FeeEstimate_EmptyExtras() throws {
        let json: [String: Any] = ["base": 100_000]
        let estimate = try FeeEstimate.fromJson(json)
        XCTAssertEqual(estimate.base, 100_000)
        XCTAssertTrue(estimate.extras.isEmpty)
    }

    // MARK: - JSON parsing: NetworkFee

    internal func test_JsonParsing_NetworkFee() throws {
        let json: [String: Any] = ["multiplier": 9, "subtotal": 900_000]
        let fee = try NetworkFee.fromJson(json)
        XCTAssertEqual(fee.multiplier, 9)
        XCTAssertEqual(fee.subtotal, 900_000)
    }

    // MARK: - JSON parsing: FeeEstimateResponse

    internal func test_JsonParsing_FeeEstimateResponse_TopLevelKeys() throws {
        let json: [String: Any] = [
            "network": ["multiplier": 9, "subtotal": 900_000] as [String: Any],
            "node": ["base": 100_000, "extras": []] as [String: Any],
            "service": ["base": 499_000_000, "extras": []] as [String: Any],
            "total": 500_000_000,
        ]
        let response = try FeeEstimateResponse.fromJson(json, mode: .state)
        XCTAssertEqual(response.mode, .state)
        XCTAssertEqual(response.networkFee.multiplier, 9)
        XCTAssertEqual(response.networkFee.subtotal, 900_000)
        XCTAssertEqual(response.nodeFee.base, 100_000)
        XCTAssertEqual(response.serviceFee.base, 499_000_000)
        XCTAssertEqual(response.total, 500_000_000)
        XCTAssertTrue(response.notes.isEmpty)
    }

    internal func test_JsonParsing_FeeEstimateResponse_MissingKeysDefaultToZero() throws {
        // The old keys (network_fee, node_fee, service_fee) must NOT be recognised
        let json: [String: Any] = [
            "network_fee": ["multiplier": 99, "subtotal": 99] as [String: Any],
            "total": 42,
        ]
        let response = try FeeEstimateResponse.fromJson(json, mode: .intrinsic)
        // network_fee is not a valid key — network should default to zeros
        XCTAssertEqual(response.networkFee.multiplier, 0)
        XCTAssertEqual(response.networkFee.subtotal, 0)
        XCTAssertEqual(response.total, 42)
    }

    // MARK: - Aggregation

    internal func test_AggregateEmpty() {
        let query = FeeEstimateQuery()
        let result = query.aggregateFeeResponses([])
        XCTAssertEqual(result.networkFee.multiplier, 0)
        XCTAssertEqual(result.networkFee.subtotal, 0)
        XCTAssertEqual(result.nodeFee.base, 0)
        XCTAssertTrue(result.nodeFee.extras.isEmpty)
        XCTAssertEqual(result.serviceFee.base, 0)
        XCTAssertTrue(result.serviceFee.extras.isEmpty)
        XCTAssertEqual(result.total, 0)
        XCTAssertTrue(result.notes.isEmpty)
    }

    internal func test_AggregateTwoChunks_SumsCorrectly() {
        let extra1 = FeeExtra(name: "Bytes", included: 1024, count: 500, charged: 0, feePerUnit: 10_000, subtotal: 0)
        let extra2 = FeeExtra(name: "Bytes", included: 1024, count: 600, charged: 0, feePerUnit: 10_000, subtotal: 0)

        let chunk1 = FeeEstimateResponse(
            mode: .state,
            networkFee: NetworkFee(multiplier: 9, subtotal: 900_000),
            nodeFee: FeeEstimate(base: 100_000, extras: [extra1]),
            serviceFee: FeeEstimate(base: 200_000, extras: []),
            notes: ["note1"],
            total: 1_200_000
        )
        let chunk2 = FeeEstimateResponse(
            mode: .state,
            networkFee: NetworkFee(multiplier: 9, subtotal: 900_000),
            nodeFee: FeeEstimate(base: 100_000, extras: [extra2]),
            serviceFee: FeeEstimate(base: 200_000, extras: []),
            notes: [],
            total: 1_200_000
        )

        let query = FeeEstimateQuery()
        let result = query.aggregateFeeResponses([chunk1, chunk2])

        // Multiplier taken from first response
        XCTAssertEqual(result.networkFee.multiplier, 9)

        // Network subtotals are summed
        XCTAssertEqual(result.networkFee.subtotal, 1_800_000)

        // Node base fees are summed
        XCTAssertEqual(result.nodeFee.base, 200_000)

        // Extras are concatenated (one from each chunk)
        XCTAssertEqual(result.nodeFee.extras.count, 2)

        // Service base fees are summed
        XCTAssertEqual(result.serviceFee.base, 400_000)

        // Totals are summed
        XCTAssertEqual(result.total, 2_400_000)

        // Notes are concatenated
        XCTAssertEqual(result.notes, ["note1"])
    }

    internal func test_AggregateTwoChunks_MultiplierTakenFromFirstChunk() {
        // Second chunk has a different multiplier — should be ignored
        let chunk1 = FeeEstimateResponse(
            mode: .state,
            networkFee: NetworkFee(multiplier: 9, subtotal: 900_000),
            nodeFee: FeeEstimate(base: 100_000, extras: []),
            serviceFee: FeeEstimate(base: 0, extras: []),
            notes: [],
            total: 1_000_000
        )
        let chunk2 = FeeEstimateResponse(
            mode: .state,
            networkFee: NetworkFee(multiplier: 12, subtotal: 1_200_000),
            nodeFee: FeeEstimate(base: 100_000, extras: []),
            serviceFee: FeeEstimate(base: 0, extras: []),
            notes: [],
            total: 1_300_000
        )

        let query = FeeEstimateQuery()
        let result = query.aggregateFeeResponses([chunk1, chunk2])

        // Multiplier must come from the FIRST chunk, not the last
        XCTAssertEqual(result.networkFee.multiplier, 9)
    }

    // MARK: - HTTP error handling (tests 12, 13, 14)

    private func makeMockQuery() throws -> (FeeEstimateQuery, URLSession) {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        // Pre-freeze with TestConstants so execute() skips freezeWith(client)
        let tx = try TransferTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .freeze()
        let query = FeeEstimateQuery()
            .setMode(.intrinsic)
            .setTransaction(tx)
        query.urlSession = session
        return (query, session)
    }

    private func makeTestClient(maxAttempts: Int) -> Client {
        let client = Client.forTestnet()
        client.maxAttempts = maxAttempts
        client.minBackoff = 0
        client.maxBackoff = 0
        _ = client.setMirrorNetwork(["testnet.mirrornode.hedera.com"])
        return client
    }

    // Test 12: HTTP 400 surfaces an error immediately without retrying.
    internal func test_Http400_ThrowsImmediately() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            let response = HTTPURLResponse(
                url: URL(string: "https://testnet.mirrornode.hedera.com/api/v1/network/fees?mode=INTRINSIC")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("bad request".utf8))
        }
        defer { MockURLProtocol.requestHandler = nil }

        let (query, _) = try makeMockQuery()
        let client = makeTestClient(maxAttempts: 3)

        do {
            _ = try await query.execute(client)
            XCTFail("Expected error on HTTP 400")
        } catch {
            // Should have called the mock exactly once — no retries on 400
            XCTAssertEqual(callCount, 1)
            XCTAssertTrue(error is HError)
        }
    }

    // Test 13: HTTP 503 retries up to maxAttempts then throws.
    internal func test_Http503_RetriesAndEventuallyThrows() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            let response = HTTPURLResponse(
                url: URL(string: "https://testnet.mirrornode.hedera.com/api/v1/network/fees?mode=INTRINSIC")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("service unavailable".utf8))
        }
        defer { MockURLProtocol.requestHandler = nil }

        let (query, _) = try makeMockQuery()
        let client = makeTestClient(maxAttempts: 2)

        do {
            _ = try await query.execute(client)
            XCTFail("Expected error after exhausting retries")
        } catch {
            // Should have retried up to maxAttempts times
            XCTAssertEqual(callCount, 2)
            XCTAssertTrue(error is HError)
        }
    }

    // Test 14: Request timeout retries up to maxAttempts then throws.
    internal func test_Timeout_RetriesAndEventuallyThrows() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            throw URLError(.timedOut)
        }
        defer { MockURLProtocol.requestHandler = nil }

        let (query, _) = try makeMockQuery()
        let client = makeTestClient(maxAttempts: 2)

        do {
            _ = try await query.execute(client)
            XCTFail("Expected error after timeout retries")
        } catch {
            XCTAssertEqual(callCount, 2)
        }
    }
}

// MARK: - MockURLProtocol

private class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
