// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class ClientIntegrationTests: XCTestCase {
    internal func testInitWithMirrorNetwork() async throws {
        // Define the mirror network address for testnet
        let mirrorNetworkAddress = "testnet.mirrornode.hedera.com:443"

        // Initialize the client with the mirror network
        let client: Client
        do {
            client = try await Client.forMirrorNetwork([mirrorNetworkAddress])
        } catch {
            XCTFail("Client initialization failed with error: \(error.localizedDescription)")
            throw error
        }

        // Verify the mirror network is set correctly
        let mirrorNetwork = client.mirrorNetwork
        XCTAssertEqual(mirrorNetwork.count, 1, "Mirror network should contain exactly one address")
        XCTAssertEqual(mirrorNetwork[0], mirrorNetworkAddress, "Mirror network address mismatch")

        // Verify the main network is initialized and not nil/empty
        XCTAssertNotNil(client.network, "Main network should be initialized")
        XCTAssertFalse(client.network.isEmpty, "Main network should not be empty after mirror initialization")

        // Optional: Perform a simple query to validate client functionality (e.g., get network name or a basic info)
        // This ensures the client is not just created but usable; adjust based on SDK capabilities
        XCTAssertNoThrow(try await client.pingAll(), "Client should be able to ping the network")

        // Teardown: Close the client to release resources (if supported by SDK)
        addTeardownBlock {
            client.close()
        }
    }
}
