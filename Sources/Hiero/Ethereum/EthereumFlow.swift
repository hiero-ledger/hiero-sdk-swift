// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Flow for executing ethereum transactions.
public final class EthereumFlow {
    private static let maxEthereumDataSize: Int = 5120

    /// The raw Ethereum transaction (RLP encoded type 0, 1, and 2).
    public var ethereumData: EthereumData?

    /// Sets the raw Ethereum transaction data (RLP encoded type 0, 1, and 2).
    @discardableResult
    public func ethereumData(_ data: Data) throws -> Self {
        ethereumData = try .init(rlpBytes: data)

        return self
    }

    /// The maximum amount that the payer of the hedera transaction is willing to pay to complete the transaction.
    public var maxGasAllowance: Hbar?

    /// Sets the maximum amount that the payer of the ethereum transaction is willing to pay to complete the transaction.
    @discardableResult
    public func maxGasAllowance(_ maxGasAllowance: Hbar) -> Self {
        self.maxGasAllowance = maxGasAllowance

        return self
    }

    /// Generates the required transactions and executes them all.
    public func execute(_ client: Client, _ timeoutPerTansaction: TimeInterval? = nil) async throws
        -> TransactionResponse
    {
        guard var ethereumData = ethereumData else {
            // todo: replace this with a real error?
            fatalError("ethereumData must be set before calling `EthereumFlow.execute`")
        }

        var ethereumDataBytes = ethereumData.toBytes()

        let ethereumTransaction = EthereumTransaction()

        if let maxGasAllowance = maxGasAllowance {
            ethereumTransaction.maxGasAllowanceHbar(maxGasAllowance)
        }

        if ethereumDataBytes.count <= Self.maxEthereumDataSize {
            return try await ethereumTransaction.ethereumData(ethereumDataBytes).execute(client, timeoutPerTansaction)
        }

        let callData = ethereumData.callData
        ethereumData.callData = Data()

        let fileId = try await Self.createFile(client, callData, timeoutPerTansaction)

        ethereumDataBytes = ethereumData.toBytes()

        ethereumTransaction.callDataFileId(fileId).ethereumData(ethereumDataBytes)

        return try await ethereumTransaction.execute(client, timeoutPerTansaction)
    }

    private static func splitCallData(_ callData: Data) -> (fileCreate: Data, fileAppend: Data?) {
        let fileAppendDefaultChunkSize: Int = 4096

        if let data = callData.splitAt(fileAppendDefaultChunkSize) {
            return (Data(data.0), Data(data.1))
        }

        return (callData, nil)
    }

    private static func createFile(_ client: Client, _ callData: Data, _ timeoutPerTansaction: TimeInterval? = nil)
        async throws -> FileId
    {
        let data = splitCallData(callData)

        let fileId = try await FileCreateTransaction()
            .contents(data.fileCreate)
            .execute(client, timeoutPerTansaction)
            .getReceiptQuery()
            .execute(client, timeoutPerTansaction)
            .fileId!

        if let fileAppendData = data.fileAppend {
            // note: file append waits for receipts so we don't need to ourself
            _ = try await FileAppendTransaction()
                .fileId(fileId)
                .contents(fileAppendData)
                .executeAll(client, timeoutPerTansaction)
        }

        return fileId
    }
}
