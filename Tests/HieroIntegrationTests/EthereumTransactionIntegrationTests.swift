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
        let jumboContractBytecode = Data(
            "6080604052348015600e575f5ffd5b506101828061001c5f395ff3fe608060405234801561000f575f5ffd5b5060043610610029575f3560e01c80631e0a3f051461002d575b5f5ffd5b610047600480360381019061004291906100d0565b61005d565b6040516100549190610133565b60405180910390f35b5f5f905092915050565b5f5ffd5b5f5ffd5b5f5ffd5b5f5ffd5b5f5ffd5b5f5f83601f8401126100905761008f61006f565b5b8235905067ffffffffffffffff8111156100ad576100ac610073565b5b6020830191508360018202830111156100c9576100c8610077565b5b9250929050565b5f5f602083850312156100e6576100e5610067565b5b5f83013567ffffffffffffffff8111156101035761010261006b565b5b61010f8582860161007b565b92509250509250929050565b5f819050919050565b61012d8161011b565b82525050565b5f6020820190506101465f830184610124565b9291505056fea26469706673582212202829ebd1cf38c443e4fd3770cd4306ac4c6bb9ac2828074ae2b9cd16121fcfea64736f6c634300081e0033"
                .utf8
        )

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

    /// EIP-1559 transaction fields used for building Ethereum transactions.
    private struct EIP1559TransactionFields {
        let chainId: Data
        let nonce: Data
        let maxPriorityGas: Data
        let maxGas: Data
        let gasLimit: Data
        let contractBytes: Data
        let value: Data
        let callDataBytes: Data

        static let transactionType = Data([0x02])
    }

    /// Builds EIP-1559 Ethereum transaction data with proper RLP encoding and signing.
    private func buildEthereumTransactionData(
        privateKey: PrivateKey,
        contractId: ContractId,
        callData: ContractFunctionParameters,
        functionName: String,
        gasLimit: Data
    ) throws -> Data {
        let fields = try EIP1559TransactionFields(
            chainId: Data(hexEncoded: "012a")!,
            nonce: Data(),  // Empty for 0 in RLP
            maxPriorityGas: Data(),  // Empty for 0 in RLP
            maxGas: Data(hexEncoded: "d1385c7bf0")!,
            gasLimit: gasLimit,
            // Note: toEvmAddress() crashes in test context, using toSolidityAddress() as workaround
            contractBytes: Data(hexEncoded: contractId.toSolidityAddress())!,
            value: Data(),  // Empty for 0 in RLP
            callDataBytes: callData.toBytes(functionName)
        )

        let unsignedTx = encodeUnsignedTransaction(fields)
        let (r, s, v) = try signTransaction(unsignedTx, privateKey: privateKey)
        return encodeSignedTransaction(fields, v: v, r: r, s: s)
    }

    /// RLP encodes the unsigned EIP-1559 transaction.
    private func encodeUnsignedTransaction(_ fields: EIP1559TransactionFields) -> Data {
        var encoder = Rlp.Encoder()
        encoder.startList()
        encoder.append(fields.chainId)
        encoder.append(fields.nonce)
        encoder.append(fields.maxPriorityGas)
        encoder.append(fields.maxGas)
        encoder.append(fields.gasLimit)
        encoder.append(fields.contractBytes)
        encoder.append(fields.value)
        encoder.append(fields.callDataBytes)
        encoder.startList()  // Empty accessList
        encoder.endList()
        encoder.endList()

        var result = EIP1559TransactionFields.transactionType
        result.append(encoder.output)
        return result
    }

    /// Signs the transaction and returns (r, s, v) signature components.
    private func signTransaction(_ unsignedTx: Data, privateKey: PrivateKey) throws -> (Data, Data, Data) {
        let signature = privateKey.sign(unsignedTx)
        let r = Data(signature.prefix(32))
        let s = Data(signature.suffix(32))

        let recoveryId = privateKey.getRecoveryId(r: r, s: s, message: unsignedTx)
        guard recoveryId >= 0 else {
            throw HError(kind: .basicParse, description: "Failed to compute recovery ID")
        }

        // Recovery ID encoding: 0 = empty, 1-3 = single byte
        let v: Data = recoveryId == 0 ? Data() : Data([UInt8(recoveryId)])
        return (r, s, v)
    }

    /// RLP encodes the signed EIP-1559 transaction.
    private func encodeSignedTransaction(_ fields: EIP1559TransactionFields, v: Data, r: Data, s: Data) -> Data {
        var encoder = Rlp.Encoder()
        encoder.startList()
        encoder.append(fields.chainId)
        encoder.append(fields.nonce)
        encoder.append(fields.maxPriorityGas)
        encoder.append(fields.maxGas)
        encoder.append(fields.gasLimit)
        encoder.append(fields.contractBytes)
        encoder.append(fields.value)
        encoder.append(fields.callDataBytes)
        encoder.startList()  // Empty accessList
        encoder.endList()
        encoder.append(v)
        encoder.append(r)
        encoder.append(s)
        encoder.endList()

        var result = EIP1559TransactionFields.transactionType
        result.append(encoder.output)
        return result
    }
}
