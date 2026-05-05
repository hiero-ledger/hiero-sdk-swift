// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import SwiftDotenv

/// Example: Estimate transaction fees using `FeeEstimateQuery`.
///
/// Demonstrates both STATE and INTRINSIC estimation modes for a simple
/// `TransferTransaction`, and shows how to use the `.estimateFee()` shorthand.
///
/// Required environment variables (in .env):
///   OPERATOR_ID  — account ID of the operator (e.g. 0.0.1234)
///   OPERATOR_KEY — private key of the operator (hex-encoded DER)
///   HEDERA_NETWORK — network name (testnet, previewnet, or mainnet); defaults to testnet
@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // ─── Step 1: Build and freeze a transfer transaction ───────────────────────
        print("Building a TransferTransaction...")

        let tx = try TransferTransaction()
            .hbarTransfer(env.operatorAccountId, Hbar(-1))
            .hbarTransfer(AccountId(num: 3), Hbar(1))
            .freezeWith(client)

        print("Transaction frozen.")

        // ─── Step 2: Estimate fees with STATE mode ─────────────────────────────────
        // STATE mode uses the mirror node's latest known network state, giving the
        // most realistic preview of what the network will actually charge.
        print("\n--- STATE mode estimate ---")
        let stateEstimate = try await FeeEstimateQuery()
            .mode(.state)
            .transaction(tx)
            .execute(client)
        printEstimate(stateEstimate)

        // ─── Step 3: Estimate fees with INTRINSIC mode ─────────────────────────────
        // INTRINSIC mode ignores state-dependent factors (accounts, auto-associations,
        // custom fees, hook invocations). It only considers transaction size, signatures,
        // and declared keys — giving a deterministic lower-bound estimate.
        print("\n--- INTRINSIC mode estimate ---")
        let intrinsicEstimate = try await FeeEstimateQuery()
            .mode(.intrinsic)
            .transaction(tx)
            .execute(client)
        printEstimate(intrinsicEstimate)

        // ─── Step 4: Compare the two estimates ────────────────────────────────────
        print("\n--- Comparison ---")
        if stateEstimate.total >= intrinsicEstimate.total {
            let diff = stateEstimate.total - intrinsicEstimate.total
            print("STATE estimate is \(diff) tinycents higher than INTRINSIC.")
        } else {
            print("Estimates are equal (no extra state-dependent costs detected).")
        }
    }

    private static func printEstimate(_ r: FeeEstimateResponse) {
        let nodeSubtotal = r.node.base + r.node.extras.reduce(0) { $0 + $1.subtotal }
        let serviceSubtotal = r.service.base + r.service.extras.reduce(0) { $0 + $1.subtotal }

        print("  Network fee    : \(r.network.subtotal) tinycents  (multiplier: \(r.network.multiplier))")
        print("  Node fee       : \(nodeSubtotal) tinycents  (base: \(r.node.base))")
        for extra in r.node.extras {
            print("    + \(extra.name): charged=\(extra.charged) × \(extra.feePerUnit) = \(extra.subtotal)")
        }
        print("  Service fee    : \(serviceSubtotal) tinycents  (base: \(r.service.base))")
        for extra in r.service.extras {
            print("    + \(extra.name): charged=\(extra.charged) × \(extra.feePerUnit) = \(extra.subtotal)")
        }
        print("  Total          : \(r.total) tinycents")
    }
}

extension Environment {
    internal var operatorAccountId: AccountId {
        AccountId(self["OPERATOR_ID"]!.stringValue)!
    }

    internal var operatorKey: PrivateKey {
        PrivateKey(self["OPERATOR_KEY"]!.stringValue)!
    }

    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}
