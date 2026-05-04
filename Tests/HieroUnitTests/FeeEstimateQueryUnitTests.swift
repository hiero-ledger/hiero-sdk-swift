// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@testable import Hiero

internal final class FeeEstimateQueryUnitTests: HieroUnitTestCase {

    // MARK: - FeeEstimateMode

    internal func test_DefaultMode() {
        let query = FeeEstimateQuery()
        XCTAssertEqual(query.mode, .intrinsic)
    }

    internal func test_SetMode() {
        let query = FeeEstimateQuery()
        query.mode(.intrinsic)
        XCTAssertEqual(query.mode, .intrinsic)
        query.mode(.state)
        XCTAssertEqual(query.mode, .state)
    }

    // MARK: - Transaction getter/setter

    internal func test_SetGetTransaction() throws {
        let tx = TransferTransaction()
        let query = FeeEstimateQuery()
        XCTAssertNil(query.transaction)
        query.transaction(tx)
        XCTAssertTrue(query.transaction === tx)
    }

    internal func test_EstimateFeeExtension() throws {
        let tx = TransferTransaction()
        let query = tx.estimateFee()
        XCTAssertTrue(query.transaction === tx)
        XCTAssertEqual(query.mode, .intrinsic)
    }

    // MARK: - HighVolumeThrottle getter/setter

    internal func test_DefaultHighVolumeThrottle() {
        XCTAssertEqual(FeeEstimateQuery().highVolumeThrottle, 0)
    }

    internal func test_SetGetHighVolumeThrottle() {
        let query = FeeEstimateQuery()
        query.highVolumeThrottle(5000)
        XCTAssertEqual(query.highVolumeThrottle, 5000)
        query.highVolumeThrottle(0)
        XCTAssertEqual(query.highVolumeThrottle, 0)
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
            "high_volume_multiplier": 3,
            "network": ["multiplier": 9, "subtotal": 900_000] as [String: Any],
            "node": ["base": 100_000, "extras": []] as [String: Any],
            "service": ["base": 499_000_000, "extras": []] as [String: Any],
            "total": 500_000_000,
        ]
        let response = try FeeEstimateResponse.fromJson(json)
        XCTAssertEqual(response.highVolumeMultiplier, 3)
        XCTAssertEqual(response.network.multiplier, 9)
        XCTAssertEqual(response.network.subtotal, 900_000)
        XCTAssertEqual(response.node.base, 100_000)
        XCTAssertEqual(response.service.base, 499_000_000)
        XCTAssertEqual(response.total, 500_000_000)
    }

    internal func test_JsonParsing_FeeEstimateResponse_MissingKeysDefaultToZero() throws {
        // The old keys (network_fee, node_fee, service_fee) must NOT be recognised
        let json: [String: Any] = [
            "network_fee": ["multiplier": 99, "subtotal": 99] as [String: Any],
            "total": 42,
        ]
        let response = try FeeEstimateResponse.fromJson(json)
        // high_volume_multiplier missing → defaults to 1 (no high-volume pricing)
        XCTAssertEqual(response.highVolumeMultiplier, 1)
        // network_fee is not a valid key — network should default to zeros
        XCTAssertEqual(response.network.multiplier, 0)
        XCTAssertEqual(response.network.subtotal, 0)
        XCTAssertEqual(response.total, 42)
    }

    // MARK: - Aggregation

    internal func test_AggregateEmpty() {
        let query = FeeEstimateQuery()
        let result = query.aggregateFeeResponses([])
        XCTAssertEqual(result.highVolumeMultiplier, 1)
        XCTAssertEqual(result.network.multiplier, 0)
        XCTAssertEqual(result.network.subtotal, 0)
        XCTAssertEqual(result.node.base, 0)
        XCTAssertTrue(result.node.extras.isEmpty)
        XCTAssertEqual(result.service.base, 0)
        XCTAssertTrue(result.service.extras.isEmpty)
        XCTAssertEqual(result.total, 0)
    }

    internal func test_AggregateTwoChunks_SumsCorrectly() {
        let extra1 = FeeExtra(name: "Bytes", included: 1024, count: 500, charged: 0, feePerUnit: 10_000, subtotal: 0)
        let extra2 = FeeExtra(name: "Bytes", included: 1024, count: 600, charged: 0, feePerUnit: 10_000, subtotal: 0)

        let chunk1 = FeeEstimateResponse(
            network: NetworkFee(multiplier: 9, subtotal: 900_000),
            node: FeeEstimate(base: 100_000, extras: [extra1]),
            service: FeeEstimate(base: 200_000, extras: []),
            total: 1_200_000
        )
        let chunk2 = FeeEstimateResponse(
            network: NetworkFee(multiplier: 9, subtotal: 900_000),
            node: FeeEstimate(base: 100_000, extras: [extra2]),
            service: FeeEstimate(base: 200_000, extras: []),
            total: 1_200_000
        )

        let query = FeeEstimateQuery()
        let result = query.aggregateFeeResponses([chunk1, chunk2])

        // Multiplier taken from first response
        XCTAssertEqual(result.network.multiplier, 9)

        // Network subtotal = aggregated node subtotal × multiplier (200_000 × 9)
        XCTAssertEqual(result.network.subtotal, 1_800_000)

        // Node base fees are summed
        XCTAssertEqual(result.node.base, 200_000)

        // Extras are concatenated (one from each chunk)
        XCTAssertEqual(result.node.extras.count, 2)

        // Service base fees are summed
        XCTAssertEqual(result.service.base, 400_000)

        // Totals are summed
        XCTAssertEqual(result.total, 2_400_000)
    }

    internal func test_AggregateTwoChunks_MultiplierTakenFromFirstChunk() {
        // Second chunk has a different multiplier — should be ignored
        let chunk1 = FeeEstimateResponse(
            network: NetworkFee(multiplier: 9, subtotal: 900_000),
            node: FeeEstimate(base: 100_000, extras: []),
            service: FeeEstimate(base: 0, extras: []),
            total: 1_000_000
        )
        let chunk2 = FeeEstimateResponse(
            network: NetworkFee(multiplier: 12, subtotal: 1_200_000),
            node: FeeEstimate(base: 100_000, extras: []),
            service: FeeEstimate(base: 0, extras: []),
            total: 1_300_000
        )

        let query = FeeEstimateQuery()
        let result = query.aggregateFeeResponses([chunk1, chunk2])

        // Multiplier must come from the FIRST chunk, not the last
        XCTAssertEqual(result.network.multiplier, 9)

        // network.subtotal = aggregated node subtotal × first multiplier (200_000 × 9 = 1_800_000)
        // NOT the sum of per-chunk network subtotals (900_000 + 1_200_000 = 2_100_000)
        XCTAssertEqual(result.network.subtotal, 1_800_000)
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
            .mode(.intrinsic)
            .transaction(tx)
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

    // Test 13a: HTTP 500 retries up to maxAttempts then throws (mirror node spec uses 500 for service unavailable).
    internal func test_Http500_RetriesAndEventuallyThrows() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            let response = HTTPURLResponse(
                url: URL(string: "https://testnet.mirrornode.hedera.com/api/v1/network/fees?mode=INTRINSIC")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("internal server error".utf8))
        }
        defer { MockURLProtocol.requestHandler = nil }

        let (query, _) = try makeMockQuery()
        let client = makeTestClient(maxAttempts: 2)

        do {
            _ = try await query.execute(client)
            XCTFail("Expected error after exhausting retries")
        } catch {
            XCTAssertEqual(callCount, 2)
            XCTAssertTrue(error is HError)
        }
    }

    // Test 13b: HTTP 503 retries up to maxAttempts then throws.
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

    // Test 2: An unfrozen transaction is automatically frozen by execute().
    internal func test_UnfrozenTransaction_AutoFreezes() async throws {
        let minimalResponseJson = """
            {
              "high_volume_multiplier": 1,
              "network": {"multiplier": 9, "subtotal": 900000},
              "node": {"base": 100000, "extras": []},
              "service": {"base": 200000, "extras": []},
              "total": 1200000
            }
            """
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://testnet.mirrornode.hedera.com/api/v1/network/fees?mode=INTRINSIC")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(minimalResponseJson.utf8))
        }
        defer { MockURLProtocol.requestHandler = nil }

        // Create an intentionally unfrozen transaction.
        // Pre-set nodeAccountIds and transactionId so freezeWith() doesn't do a
        // network lookup (which would cancel in a unit-test context).
        let tx = try TransferTransaction()
            .hbarTransfer(AccountId(num: 2), Hbar(1))
            .hbarTransfer(AccountId(num: 3), Hbar(-1))
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
        XCTAssertFalse(tx.isFrozen, "Transaction should be unfrozen before execute()")

        let (query, _) = try makeMockQuery()
        query.transaction(tx)
        let client = makeTestClient(maxAttempts: 1)

        // execute() should auto-freeze the transaction and succeed
        let result = try await query.execute(client)
        XCTAssertTrue(tx.isFrozen, "Transaction should be frozen after execute()")
        XCTAssertGreaterThan(result.total, 0)
    }

    // Test 20: high_volume_throttle appears in the request URL when set to a non-zero value.
    internal func test_HighVolumeThrottle_AppearsInUrl() async throws {
        var capturedUrl: URL?
        MockURLProtocol.requestHandler = { request in
            capturedUrl = request.url
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        defer { MockURLProtocol.requestHandler = nil }

        let (query, _) = try makeMockQuery()
        query.highVolumeThrottle(5000)
        let client = makeTestClient(maxAttempts: 1)

        _ = try? await query.execute(client)

        let urlString = try XCTUnwrap(capturedUrl).absoluteString
        XCTAssertTrue(urlString.contains("high_volume_throttle=5000"), "URL missing high_volume_throttle: \(urlString)")
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
