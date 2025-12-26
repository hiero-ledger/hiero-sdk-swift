// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TokenUpdateNftsTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_UpdateNftMetadata() async throws {
        // Given
        let nftCount = 4
        let initialMetadataList = Array(repeating: Data([9, 1, 6]), count: nftCount)
        let updatedMetadata = Data([3, 4])
        let updatedMetadataList = Array(repeating: updatedMetadata, count: nftCount)

        let adminKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(TokenType.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
                .expirationTime(.now + .minutes(5)),
            adminKey: adminKey,
            supplyKey: supplyKey
        )

        let receipt = try await TokenMintTransaction()
            .metadata(initialMetadataList)
            .tokenId(tokenId)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(receipt.serials)

        // When
        _ = try await TokenUpdateNftsTransaction()
            .tokenId(tokenId)
            .serials(nftSerials)
            .metadata(updatedMetadata)
            .freezeWith(testEnv.client)
            .sign(metadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let newMetadataList = try await getMetadataList(testEnv.client, tokenId, nftSerials)
        XCTAssertEqual(newMetadataList, updatedMetadataList)
    }

    internal func test_UpdateNftMetadataOfPartialCollection() async throws {
        // Given
        let nftCount = 4
        let initialMetadataList = Array(repeating: Data([9, 1, 6]), count: nftCount)
        let updatedMetadata = Data([3, 4])
        let updatedMetadataList = Array(repeating: updatedMetadata, count: nftCount / 2)

        let adminKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(TokenType.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(testEnv.operator.privateKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
                .expirationTime(.now + .minutes(5)),
            adminKey: adminKey,
            supplyKey: supplyKey
        )

        let receipt = try await TokenMintTransaction()
            .metadata(initialMetadataList)
            .tokenId(tokenId)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(receipt.serials)
        let nftSerialsToUpdate = nftSerials[..<(nftCount / 2)].map { UInt64($0) }

        // When
        _ = try await TokenUpdateNftsTransaction()
            .tokenId(tokenId)
            .serials(nftSerialsToUpdate)
            .metadata(updatedMetadata)
            .freezeWith(testEnv.client)
            .sign(metadataKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let metadataListAfterUpdate = try await getMetadataList(testEnv.client, tokenId, nftSerialsToUpdate)
        XCTAssertEqual(metadataListAfterUpdate, updatedMetadataList)
    }

    internal func test_CantUpdateMetadataNoSignedMetadataKey() async throws {
        // Given
        let nftCount = 4
        let initialMetadataList = Array(repeating: Data([9, 1, 6]), count: nftCount)
        let updatedMetadata = Data([3, 4])

        let adminKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let metadataKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(TokenType.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .metadataKey(.single(metadataKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .sign(adminKey),
            adminKey: adminKey,
            supplyKey: supplyKey
        )

        let receipt = try await TokenMintTransaction()
            .metadata(initialMetadataList)
            .tokenId(tokenId)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(receipt.serials)

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateNftsTransaction()
                .tokenId(tokenId)
                .serials(nftSerials)
                .metadata(updatedMetadata)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_CantUpdateMetadataNoSetMetadataKey() async throws {
        // Given
        let nftCount = 4
        let initialMetadataList = [
            Data(Array(repeating: [9, 1, 6], count: (nftCount / [9, 1, 6].count) + 1).flatMap { $0 }.prefix(nftCount))
        ]
        let updatedMetadata = Data([3, 4])

        let metadataKey = PrivateKey.generateEd25519()
        let supplyKey = PrivateKey.generateEd25519()
        let adminKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .tokenType(TokenType.nonFungibleUnique)
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .supplyKey(.single(supplyKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .sign(adminKey),
            adminKey: adminKey,
            supplyKey: supplyKey
        )

        let receipt = try await TokenMintTransaction()
            .metadata(initialMetadataList)
            .tokenId(tokenId)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let nftSerials = try XCTUnwrap(receipt.serials)

        // When / Then
        await assertReceiptStatus(
            try await TokenUpdateNftsTransaction()
                .tokenId(tokenId)
                .serials(nftSerials)
                .metadata(updatedMetadata)
                .freezeWith(testEnv.client)
                .sign(metadataKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }
}

internal func getMetadataList(_ client: Client, _ tokenId: TokenId, _ serials: [UInt64]) async throws -> [Data] {
    let metadataList: [Data] = try await withThrowingTaskGroup(
        of: Data.self,
        body: { group in
            var results = [Data]()

            // Iterate over serials, launching a new task for each
            for serial in serials {
                group.addTask {
                    let nftId = NftId(tokenId: tokenId, serial: UInt64(serial))
                    // Execute the query and return the result
                    return try await TokenNftInfoQuery().nftId(nftId).execute(client).metadata
                }
            }

            // Collect results from all tasks
            for try await result in group {
                results.append(result)
            }

            return results
        })

    return metadataList
}
