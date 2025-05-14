// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        // Defaults the operator account ID and key such that all generated transactions will be paid for
        // by this account and be signed by this key
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Generate a higher-privileged key.
        let adminKey = PrivateKey.generateEd25519()

        // Generate the lower-privileged keys that will be modified.
        // Note: Lower-privileged keys are Wipe, Supply, and updated Supply key..
        let supplyKey = PrivateKey.generateEd25519()
        let wipeKey = PrivateKey.generateEd25519()
        let newSupplyKey = PrivateKey.generateEd25519()

        let unusableKey = try PublicKey.fromStringEd25519(
            "0x0000000000000000000000000000000000000000000000000000000000000000")

        // Create an NFT token with admin, wipe, and supply key.
        let tokenId = try await TokenCreateTransaction()
            .name("Example NFT")
            .symbol("ENFT")
            .tokenType(TokenType.nonFungibleUnique)
            .treasuryAccountId(env.operatorAccountId)
            .adminKey(.single(adminKey.publicKey))
            .wipeKey(.single(wipeKey.publicKey))
            .supplyKey(.single(supplyKey.publicKey))
            .expirationTime(Timestamp.now + .minutes(5))
            .freezeWith(client)
            .sign(adminKey)
            .execute(client)
            .getReceipt(client)
            .tokenId!

        let tokenInfo = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(client)

        print("Admin Key: \(tokenInfo.adminKey!)")
        print("Wipe Key: \(tokenInfo.wipeKey!)")
        print("Supply Key: \(tokenInfo.supplyKey!)")

        print("------------------------------------")
        print("Removing Wipe Key...")

        // Remove the wipe key with empty Keylist, signing with the admin key.
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .wipeKey(.keyList([]))
            .keyVerificationMode(TokenKeyValidation.fullValidation)
            .freezeWith(client)
            .sign(adminKey)
            .execute(client)
            .getReceipt(client)

        let tokenInfoAfterWipeKeyUpdate = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(client)

        print("Wipe Key (after removal): \(String(describing: tokenInfoAfterWipeKeyUpdate.wipeKey))")
        print("------------------------------------")
        print("Removing Admin Key...")

        // Remove the admin key with empty Keylist, signing with the admin key.
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .adminKey(.keyList([]))
            .keyVerificationMode(TokenKeyValidation.noValidation)
            .freezeWith(client)
            .sign(adminKey)
            .execute(client)
            .getReceipt(client)

        let tokenInfoAfterAdminKeyUpdate = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(client)

        print("Admin Key (after removal): \(String(describing:tokenInfoAfterAdminKeyUpdate.adminKey))")

        print("------------------------------------")
        print("Update Supply Key...")

        // Update the supply key with a new key, signing with the old supply key and the new supply key.
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .supplyKey(.single(newSupplyKey.publicKey))
            .keyVerificationMode(TokenKeyValidation.fullValidation)
            .freezeWith(client)
            .sign(supplyKey)
            .sign(newSupplyKey)
            .execute(client)
            .getReceipt(client)

        let tokenInfoAfterSupplyKeyUpdate = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(client)

        print("Supply Key (after update): \(String(describing: tokenInfoAfterSupplyKeyUpdate.supplyKey))")

        print("------------------------------------")
        print("Removing Supply Key...")

        // Remove the supply key with unusable key, signing with the new supply key.
        _ = try await TokenUpdateTransaction()
            .tokenId(tokenId)
            .supplyKey(.single(unusableKey))
            .keyVerificationMode(TokenKeyValidation.noValidation)
            .freezeWith(client)
            .sign(newSupplyKey)
            .execute(client)
            .getReceipt(client)

        let tokenInfoAfterSupplyKeyRemoval = try await TokenInfoQuery()
            .tokenId(tokenId)
            .execute(client)

        print("Supply Key (after removal): \(String(describing: tokenInfoAfterSupplyKeyRemoval.supplyKey))")
    }
}
