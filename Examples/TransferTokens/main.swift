// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        let operatorKey = env.operatorKey
        let operatorAccountId = env.operatorAccountId

        client.setOperator(operatorAccountId, operatorKey)

        let (privateKey1, accountId1) = try await createAccount(client, accountNumber: 1)
        let (privateKey2, accountId2) = try await createAccount(client, accountNumber: 2)

        let tokenId = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .decimals(3)
            .initialSupply(1_000_000)
            .treasuryAccountId(operatorAccountId)
            .adminKey(.single(operatorKey.publicKey))
            .freezeKey(.single(operatorKey.publicKey))
            .wipeKey(.single(operatorKey.publicKey))
            .kycKey(.single(operatorKey.publicKey))
            .supplyKey(.single(operatorKey.publicKey))
            .expirationTime(Timestamp.now + .hours(2))
            .freezeDefault(false)
            .execute(client)
            .getReceipt(client)
            .tokenId!

        print("token = \(tokenId)")

        _ = try await TokenAssociateTransaction()
            .accountId(accountId1)
            .tokenIds([tokenId])
            .freezeWith(client)
            .sign(privateKey1)
            .execute(client)
            .getReceipt(client)

        print("Associated account \(accountId1) with token \(tokenId)")

        _ = try await TokenAssociateTransaction()
            .accountId(accountId2)
            .tokenIds([tokenId])
            .freezeWith(client)
            .sign(privateKey2)
            .execute(client)
            .getReceipt(client)

        print("Associated account \(accountId2) with token \(tokenId)")

        _ = try await TokenGrantKycTransaction()
            .accountId(accountId1)
            .tokenId(tokenId)
            .freezeWith(client)
            .execute(client)
            .getReceipt(client)

        print("Granted KYC for account \(accountId1) on token \(tokenId)")

        _ = try await TokenGrantKycTransaction()
            .accountId(accountId2)
            .tokenId(tokenId)
            .freezeWith(client)
            .execute(client)
            .getReceipt(client)

        print("Granted KYC for account \(accountId2) on token \(tokenId)")

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, operatorAccountId, -10)
            .tokenTransfer(tokenId, accountId1, 10)
            .execute(client)
            .getReceipt(client)

        print("Sent 10 tokens from account \(operatorAccountId) to account \(accountId1) on token \(tokenId)")

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, accountId1, -10)
            .tokenTransfer(tokenId, accountId2, 10)
            .freezeWith(client)
            .sign(privateKey1)
            .execute(client)
            .getReceipt(client)

        print("Sent 10 tokens from account \(accountId1) to account \(accountId2) on token \(tokenId)")

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, accountId2, -10)
            .tokenTransfer(tokenId, accountId1, 10)
            .freezeWith(client)
            .sign(privateKey2)
            .execute(client)
            .getReceipt(client)

        print("Sent 10 tokens from account \(accountId2) to account \(accountId1) on token \(tokenId)")

        _ = try await TokenWipeTransaction()
            .accountId(accountId1)
            .tokenId(tokenId)
            .amount(10)
            .freezeWith(client)
            .sign(privateKey1)
            .execute(client)
            .getReceipt(client)

        print("Wiped balance of \(tokenId) from account \(accountId1)")

        _ = try await TokenDeleteTransaction().tokenId(tokenId).execute(client).getReceipt(client)
        print("Deleted token \(tokenId)")

        try await deleteAccount(client, operatorAccountId: operatorAccountId, accountNumber: 1, privateKey1, accountId1)
        try await deleteAccount(client, operatorAccountId: operatorAccountId, accountNumber: 2, privateKey2, accountId2)
    }

    private static func createAccount(_ client: Client, accountNumber: Int) async throws -> (PrivateKey, AccountId) {
        let privateKey = PrivateKey.generateEd25519()
        print("private key  = \(privateKey)")
        print("public key = \(privateKey.publicKey)")

        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(privateKey.publicKey))
            .initialBalance(.fromTinybars(1000))
            .execute(client)
            .getReceipt(client)

        let accountId = receipt.accountId!
        print("created accountId\(accountNumber): \(accountId)")

        return (privateKey, accountId)
    }

    private static func deleteAccount(
        _ client: Client,
        operatorAccountId: AccountId,
        accountNumber: Int,
        _ privateKey: PrivateKey,
        _ accountId: AccountId
    ) async throws {
        _ = try await AccountDeleteTransaction()
            .accountId(accountId)
            .transferAccountId(operatorAccountId)
            .freezeWith(client)
            .sign(privateKey)
            .execute(client)
            .getReceipt(client)

        print("deleted accountId\(accountNumber): \(accountId)")
    }
}
