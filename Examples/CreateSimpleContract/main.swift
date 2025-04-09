// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let bytecode = try await HieroExampleUtilities.Resources.simpleContract

        // create the contract's bytecode file
        let fileTransactionResponse = try await FileCreateTransaction()
            // Use the same key as the operator to "own" this file
            .keys([.single(env.operatorKey.publicKey)])
            .contents(bytecode.data(using: .utf8)!)
            .execute(client)

        let fileReceipt = try await fileTransactionResponse.getReceipt(client)
        let newFileId = fileReceipt.fileId!

        print("contract bytecode file: \(newFileId)")

        let contractTransactionResponse = try await ContractCreateTransaction()
            .bytecodeFileId(newFileId)
            .gas(500000)
            .adminKey(.single(env.operatorKey.publicKey))
            .constructorParameters(ContractFunctionParameters().addString("hello from hedera!"))
            .execute(client)

        let contractReceipt = try await contractTransactionResponse.getReceipt(client)
        let newContractId = contractReceipt.contractId!

        print("new contract ID: \(newContractId)")

        let contractCallResult = try await ContractCallQuery()
            .contractId(newContractId)
            .gas(500000)
            .function("greet")
            .execute(client)

        if let err = contractCallResult.errorMessage {
            print("error calling contract: \(err)")
            return
        }

        let message = contractCallResult.getString(0)
        print("contract returned message: \(String(describing: message))")

        // now delete the contract
        _ = try await ContractDeleteTransaction()
            .contractId(newContractId)
            .transferAccountId(env.operatorAccountId)
            .execute(client)
            .getReceipt(client)

        print("Contract successfully deleted")
    }
}
