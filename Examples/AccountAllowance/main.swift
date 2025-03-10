// SPDX-License-Identifier: Apache-2.0

import Hiero
import SwiftDotenv

private struct Account {
    internal let key: PrivateKey
    internal let id: AccountId
    internal let name: StaticString
}

private struct Accounts: Sequence {
    typealias Element = Account

    typealias Iterator = Array<Element>.Iterator

    func makeIterator() -> Iterator {
        [alice, bob, charlie].makeIterator()
    }

    internal let alice: Account
    internal let bob: Account
    internal let charlie: Account

    internal func printBalances(_ client: Client) async throws {
        for account in self {
            let balance = try await AccountBalanceQuery(accountId: account.id).execute(client).hbars
            print("\(account.name)'s balance: \(balance)")
        }
    }
}

private func createAccount(_ client: Client, _ name: StaticString) async throws -> Account {
    let key = PrivateKey.generateEd25519()

    let reciept = try await AccountCreateTransaction()
        .keyWithoutAlias(.single(key.publicKey))
        .initialBalance(5)
        .accountMemo("[sdk::swift::accountAllowanceExample::\(name)]")
        .execute(client)
        .getReceipt(client)

    let accountId = reciept.accountId!

    return Account(key: key, id: accountId, name: name)
}

private func createAccounts(_ client: Client) async throws -> Accounts {
    print("Creating accounts")

    async let alice = createAccount(client, "Alice")
    async let bob = createAccount(client, "Bob")
    async let charlie = createAccount(client, "Charlie")

    let accounts = try await Accounts(alice: alice, bob: bob, charlie: charlie)

    for account in accounts {
        print("\(account.name)'s ID: \(account.id)")
    }

    return accounts
}

/// Transfer from `alice` (0) to `charlie` (2) via `bob`'s allowance.
private func transfer(_ client: Client, _ accounts: Accounts, _ value: Hbar) async throws {
    let (alice, bob, charlie) = (accounts.alice, accounts.bob, accounts.charlie)

    // `approved{Hbar,Token}Transfer()` means that the transfer has been approved by an allowance
    // The allowance spender must be pay the fee for the transaction.
    // use `transactionId()` to set the account ID that will pay the fee for the transaction.
    _ = try await TransferTransaction()
        .approvedHbarTransfer(alice.id, -value)
        .hbarTransfer(charlie.id, value)
        .transactionId(.generateFrom(bob.id))
        .freezeWith(client)
        .sign(bob.key)
        .execute(client)
        .getReceipt(client)
}

private func demonstrateAllowances(_ client: Client, _ accounts: Accounts) async throws {
    let firstAllowanceValue: Hbar = 2
    let firstTransferValue: Hbar = 1
    let secondAllowanceValue: Hbar = 3
    let secondTransferValue: Hbar = 2

    let (alice, bob, charlie) = (accounts.alice, accounts.bob, accounts.charlie)

    print("Approving an allowance of \(firstAllowanceValue) with owner \(alice.name) and spender \(bob.name)")

    _ = try await AccountAllowanceApproveTransaction()
        .approveHbarAllowance(alice.id, bob.id, firstAllowanceValue)
        .freezeWith(client)
        .sign(alice.key)
        .execute(client)
        .getReceipt(client)

    try await accounts.printBalances(client)

    print(
        "Transferring \(firstTransferValue) from \(alice.name) to \(charlie.name), "
            + "but the transaction is signed only by \(bob.name) (\(bob.name) is dipping into their allowance from \(alice.name)"
    )

    try await transfer(client, accounts, firstTransferValue)

    let currentBalance = firstAllowanceValue - firstTransferValue

    print(
        "Transfer succeeded. \(bob.name) should now have \(currentBalance) left in their allowance."
    )

    try await accounts.printBalances(client)

    print(
        "Attempting to transfer \(secondTransferValue) from \(alice.name) to \(charlie.name) using \(bob.name)'s allowance."
    )

    print(
        "This should fail, because there is only \(currentBalance) left in \(bob.name)'s allowance."
    )

    do {
        try await transfer(client, accounts, secondTransferValue)
        print("The transfer succeeded. This should not happen.")
    } catch {
        print("The transfer failed as expected: \(String(describing: error))")
    }

    print(
        "Adjusting \(bob.name)'s allowance to \(secondAllowanceValue)."
    )

    _ = try await AccountAllowanceApproveTransaction()
        .approveHbarAllowance(alice.id, bob.id, secondAllowanceValue)
        .freezeWith(client)
        .sign(alice.key)
        .execute(client)
        .getReceipt(client)

    print(
        "Attempting to transfer \(secondTransferValue) from \(alice.name) to \(charlie.name) using \(bob.name)'s allowance again."
    )

    print("This time it should succeed.")

    try await transfer(client, accounts, secondTransferValue)

    print("Transfer succeeded.")

    try await accounts.printBalances(client)

    print("Deleting \(bob.name)'s allowance")

    _ = try await AccountAllowanceApproveTransaction()
        .approveHbarAllowance(alice.id, bob.id, .zero)
        .freezeWith(client)
        .sign(alice.key)
        .execute(client)
        .getReceipt(client)
}

private func cleanUp(
    _ client: Client,
    _ operatorId: AccountId,
    _ accounts: Accounts
) async throws {
    print("Cleaning up...")

    for account in accounts {
        _ = try await AccountDeleteTransaction()
            .accountId(account.id)
            .transferAccountId(operatorId)
            .freezeWith(client)
            .sign(account.key)
            .execute(client)
            .getReceipt(client)

        print("Deleted `\(account.name)` (was \(account.id))")
    }
}

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let accounts = try await createAccounts(client)
        try await demonstrateAllowances(client, accounts)
        try await cleanUp(client, env.operatorAccountId, accounts)
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
