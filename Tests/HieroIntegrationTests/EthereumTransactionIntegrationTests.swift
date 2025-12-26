// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal class EthereumTransactionIntegrationTests: HieroIntegrationTestCase {

    internal func test_SignerNonce() async throws {
        // Given
        let ecdsaPrivateKey = PrivateKey.generateEcdsa()
        let aliasAccountId = ecdsaPrivateKey.toAccountId(shard: 0, realm: 0)

        _ = try await TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .hbarTransfer(aliasAccountId, Hbar(1))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try await createContractBytecodeFile()

        let contractId = try await createContract(
            ContractCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .gas(1_000_000)
                .constructorParameters(ContractFunctionParameters().addString("hello from hiero").toBytes())
                .bytecodeFileId(fileId)
                .contractMemo("[e2e::EthereumTransaction]"),
            adminKey: testEnv.operator.privateKey
        )

        let ethereumData = try buildEthereumTransactionData(
            privateKey: ecdsaPrivateKey,
            contractId: contractId,
            callData: ContractFunctionParameters().addString("new message"),
            functionName: "setMessage",
            gasLimit: Data(hexEncoded: "0249f0")!  // 150k
        )

        // When
        let record = try await EthereumTransaction()
            .ethereumData(ethereumData)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        XCTAssertEqual(record.contractFunctionResult?.signerNonce, 1)
    }

    internal func test_JumboTransaction() async throws {
        // Given
        let jumboContractBytecode =
            "6080604052348015600e575f5ffd5b506101828061001c5f395ff3fe608060405234801561000f575f5ffd5b5060043610610029575f3560e01c80631e0a3f051461002d575b5f5ffd5b610047600480360381019061004291906100d0565b61005d565b6040516100549190610133565b60405180910390f35b5f5f905092915050565b5f5ffd5b5f5ffd5b5f5ffd5b5f5ffd5b5f5ffd5b5f5f83601f8401126100905761008f61006f565b5b8235905067ffffffffffffffff8111156100ad576100ac610073565b5b6020830191508360018202830111156100c9576100c8610077565b5b9250929050565b5f5f602083850312156100e6576100e5610067565b5b5f83013567ffffffffffffffff8111156101035761010261006b565b5b61010f8582860161007b565b92509250509250929050565b5f819050919050565b61012d8161011b565b82525050565b5f6020820190506101465f830184610124565b9291505056fea26469706673582212202829ebd1cf38c443e4fd3770cd4306ac4c6bb9ac2828074ae2b9cd16121fcfea64736f6c634300081e0033"
            .data(using: .utf8)!

        let ecdsaPrivateKey = PrivateKey.generateEcdsa()
        let aliasAccountId = ecdsaPrivateKey.toAccountId(shard: 0, realm: 0)

        _ = try await TransferTransaction()
            .hbarTransfer(testEnv.operator.accountId, Hbar(-100))
            .hbarTransfer(aliasAccountId, Hbar(100))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try await createFile(
            FileCreateTransaction()
                .keys([.single(testEnv.operator.privateKey.publicKey)])
                .contents(jumboContractBytecode),
            key: testEnv.operator.privateKey
        )

        let contractId = try await createContract(
            ContractCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .gas(300_000)
                .bytecodeFileId(fileId),
            adminKey: testEnv.operator.privateKey
        )

        let largeCalldata = Data(repeating: 0, count: 1024 * 120)
        let ethereumData = try buildEthereumTransactionData(
            privateKey: ecdsaPrivateKey,
            contractId: contractId,
            callData: ContractFunctionParameters().addBytes(largeCalldata),
            functionName: "consumeLargeCalldata",
            gasLimit: Data(hexEncoded: "3567E0")!  // 3.5M gas for jumbo tx
        )

        // When
        let record = try await EthereumTransaction()
            .ethereumData(ethereumData)
            .execute(testEnv.client)
            .getRecord(testEnv.client)

        // Then
        XCTAssertEqual(record.contractFunctionResult?.signerNonce, 1)
    }

    // MARK: - Helper Methods

    /// Builds EIP-1559 Ethereum transaction data with proper RLP encoding and signing.
    ///
    /// - Parameters:
    ///   - privateKey: The ECDSA private key to sign the transaction.
    ///   - contractId: The contract to call.
    ///   - callData: The function parameters.
    ///   - functionName: The name of the function to call.
    ///   - gasLimit: The gas limit for the transaction.
    /// - Returns: The fully encoded Ethereum transaction data.
    private func buildEthereumTransactionData(
        privateKey: PrivateKey,
        contractId: ContractId,
        callData: ContractFunctionParameters,
        functionName: String,
        gasLimit: Data
    ) throws -> Data {
        let chainId = Data(hexEncoded: "012a")!
        let nonce = Data()  // Empty for 0 in RLP
        let maxPriorityGas = Data()  // Empty for 0 in RLP
        let maxGas = Data(hexEncoded: "d1385c7bf0")!
        // Note: toEvmAddress() crashes in test context, using toSolidityAddress() as workaround
        let contractBytes = Data(hexEncoded: try contractId.toSolidityAddress())!
        let value = Data()  // Empty for 0 in RLP
        let callDataBytes = callData.toBytes(functionName)

        let type = Data([0x02])

        // RLP encode the unsigned transaction
        var encoder = Rlp.Encoder()
        encoder.startList()
        encoder.append(chainId)
        encoder.append(nonce)
        encoder.append(maxPriorityGas)
        encoder.append(maxGas)
        encoder.append(gasLimit)
        encoder.append(contractBytes)
        encoder.append(value)
        encoder.append(callDataBytes)
        encoder.startList()  // Empty accessList
        encoder.endList()
        encoder.endList()
        let unsignedSequence = encoder.output

        var messageToSign = type
        messageToSign.append(unsignedSequence)

        // Sign the message
        let signature = privateKey.sign(messageToSign)
        let r = Data(signature.prefix(32))
        let s = Data(signature.suffix(32))

        // Get the recovery ID dynamically
        let recoveryId = privateKey.getRecoveryId(r: r, s: s, message: messageToSign)
        guard recoveryId >= 0 else {
            throw HError(kind: .basicParse, description: "Failed to compute recovery ID")
        }

        // Recovery ID encoding: 0 = empty, 1-3 = single byte
        let v: Data = recoveryId == 0 ? Data() : Data([UInt8(recoveryId)])

        // RLP encode the signed transaction
        var signedEncoder = Rlp.Encoder()
        signedEncoder.startList()
        signedEncoder.append(chainId)
        signedEncoder.append(nonce)
        signedEncoder.append(maxPriorityGas)
        signedEncoder.append(maxGas)
        signedEncoder.append(gasLimit)
        signedEncoder.append(contractBytes)
        signedEncoder.append(value)
        signedEncoder.append(callDataBytes)
        signedEncoder.startList()  // Empty accessList
        signedEncoder.endList()
        signedEncoder.append(v)
        signedEncoder.append(r)
        signedEncoder.append(s)
        signedEncoder.endList()
        let signedSequence = signedEncoder.output

        var ethereumData = type
        ethereumData.append(signedSequence)

        return ethereumData
    }
}
