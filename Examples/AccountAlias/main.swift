// SPDX-License-Identifier: Apache-2.0
import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Hiero supports a form of auto account creation.
        //
        // You can "create" an account by generating a private key, and then deriving the public key,
        // without any need to interact with the Hiero network.  The public key more or less acts as the user's
        // account ID.  This public key is an account's aliasKey: a public key that aliases (or will eventually alias)
        // to a Hiero account.
        //
        // An AccountId takes one of two forms: a normal `AccountId` with no `aliasKey` takes the form 0.0.123,
        // while an account ID with an `aliasKey` takes the form
        // 0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf7777
        // Note the prefix of "0.0." indicating the shard and realm.  Also note that the aliasKey is stringified
        // as a hex-encoded ASN1 DER representation of the key.
        //
        // An AccountId with an aliasKey can be used just like a normal AccountId for the purposes of queries and
        // transactions, however most queries and transactions involving such an AccountId won't work until Hbar has
        // been transferred to the aliasKey account.
        //
        // There is no record in the Hiero network of an account associated with a given `aliasKey`
        // until an amount of Hbar is transferred to the account.  The moment that Hbar is transferred to that `aliasKey`
        // AccountId is the moment that that account actually begins to exist in the Hiero ledger.

        print(#""Creating" a new account"#)

        let privateKey = PrivateKey.generateEd25519()
        let publicKey = privateKey.publicKey

        // Assuming that the target shard and realm are known.
        // For now they are virtually always 0 and 0.
        let aliasAccountId = publicKey.toAccountId(shard: 0, realm: 0)

        print("New account ID: \(aliasAccountId)")
        print("Just the aliasKey: \(String(describing: aliasAccountId.alias))")

        // Note that no queries or transactions have taken place yet.
        // This account "creation" process is entirely local.
        //
        // AccountId.fromString can construct an AccountId with an aliasKey.
        // It expects a string of the form 0.0.123 in the case of a normal AccountId, or of the form
        // 0.0.302a300506032b6570032100114e6abc371b82dab5c15ea149f02d34a012087b163516dd70f44acafabf7777
        // in the case of an AccountId with an alias.  Note the prefix of "0.0." to indicate the shard and realm.
        //
        // If the shard and realm are known, you may use PublicKey.fromString().toAccountId() to construct the
        // aliasKey AccountId.

        print("Transferring some Hbar to the new account")
        _ = try await TransferTransaction()
            .hbarTransfer(env.operatorAccountId, -10)
            .hbarTransfer(aliasAccountId, 10)
            .execute(client)
            .getReceipt(client)

        let balance = try await AccountBalanceQuery()
            .accountId(aliasAccountId)
            .execute(client)

        print("Balances of the new account: \(balance)")

        let info = try await AccountInfoQuery()
            .accountId(aliasAccountId)
            .execute(client)

        print("Info about the new account: \(info)")

        // Note that once an account exists in the ledger, it is assigned a normal AccountId, which can be retrieved
        // via an AccountInfoQuery.
        //
        // Users may continue to refer to the account by its aliasKey AccountId, but they may also
        // now refer to it by its normal AccountId.

        print("the normal account ID: \(info.accountId)")
        print("the alias key: \(String(describing: info.aliasKey))")
        print("Example complete!")
    }
}

extension Environment {
    /// Account ID for the operator to use in this example.
    internal var operatorAccountId: AccountId {
        AccountId(self["OPERATOR_ID"]!.stringValue)!
    }

    /// Private key for the operator to use in this example.
    internal var operatorKey: PrivateKey {
        PrivateKey(self["OPERATOR_KEY"]!.stringValue)!
    }

    /// The name of the hedera network this example should be ran against.
    ///
    /// Testnet by default.
    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}
