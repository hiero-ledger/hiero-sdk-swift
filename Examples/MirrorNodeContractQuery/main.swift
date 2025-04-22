// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        /// Grab the environment variables.
        let env = try Dotenv.load()

        /// Initialize the client based on the provided environment.
        let client = try Client.forName(env.networkName)
        client.setOperator(env.operatorAccountId, env.operatorKey)

        /// Grab the contract bytecode.
        let bytecode = try await HieroExampleUtilities.Resources.simpleContract

        // Create the contract's bytecode file.
        var txResponse = try await FileCreateTransaction()
            // Use the same key as the operator to "own" this file
            .keys([.single(env.operatorKey.publicKey)])
            .contents(bytecode.data(using: .utf8)!)
            .execute(client)
        var txReceipt = try await txResponse.getReceipt(client)

        guard let contractFileId = txReceipt.fileId else {
            print("No file created!")
            return
        }

        print("Contract bytecode file created with ID: \(contractFileId)")

        /// Create the smart contract.
        txResponse = try await ContractCreateTransaction()
            .bytecodeFileId(contractFileId)
            .gas(500_000)
            .adminKey(.single(env.operatorKey.publicKey))
            .maxTransactionFee(16)
            .execute(client)
        txReceipt = try await txResponse.getReceipt(client)

        guard let contractId = txReceipt.contractId else {
            print("No contract created!")
            return
        }

        print("Smart contract created with ID: \(contractId)")

        /// Wait 3 seconds for the mirror node to import the contract data.
        try await Task.sleep(nanoseconds: 3_000_000_000)

        /// Get the estimate amount of gas needed.
        var queryResponse = try await MirrorNodeContractEstimateGasQuery()
            .contractId(contractId)
            .sender(env.operatorAccountId)
            .gasLimit(30_000)
            .gasPrice(1234)
            .function("greet")
            .execute(client)
        /// Estimated gas returned as a hex value.
        guard let estimatedGas = UInt64(queryResponse, radix: 16) else {
            print("Unable to decode MirrorNodeContractEstimateGasQuery response")
            return
        }

        print("Estimated gas:  \(estimatedGas)")

        /// Query against consensus node with the estimated gas.
        let functionResponse = try await ContractCallQuery()
            .contractId(contractId)
            .gas(estimatedGas)
            .maxPaymentAmount(Hbar(1))
            .function("greet")
            .execute(client)

        if let err = functionResponse.errorMessage {
            print("Error calling contract: \(err)")
            return
        }

        print("Contract call result query: \(functionResponse.bytes.map { String(format: "%02x", $0) }.joined())")

        /// Simulate the call using mirror node.
        queryResponse = try await MirrorNodeContractCallQuery()
            .contractId(contractId)
            .function("greet")
            .execute(client)
        print("Contract call simulation result: \(queryResponse)")
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
