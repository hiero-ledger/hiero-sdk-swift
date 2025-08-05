// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Encapsulates optional JSON-RPC parameters common to all Hiero transactions.
///
/// This struct encapsulates common metadata such as transaction ID, memo, transaction fee limits,
/// duration, and signer keys. It is used to populate standard fields on any Hiero `Transaction`
/// instance.
///
/// - Parameters may be omitted; defaults and overrides are applied later in the transaction flow.
internal struct CommonTransactionParams {

    // MARK: - Properties

    internal var transactionId: String? = nil
    internal var maxTransactionFee: Int64? = nil
    internal var validTransactionDuration: Int64? = nil
    internal var memo: String? = nil
    internal var regenerateTransactionId: Bool? = nil
    internal var signers: [String]? = nil

    // MARK: - Initializers

    internal init(from parameters: [String: JSONObject]?, for funcName: JSONRPCMethod) throws {
        guard let params = parameters else { return }

        self.transactionId = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "transactionId", from: params, for: funcName)
        self.maxTransactionFee = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "maxTransactionFee", from: params, for: funcName)
        self.validTransactionDuration = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "validTransactionDuration", from: params, for: funcName)
        self.memo = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "memo", from: params, for: funcName)
        self.regenerateTransactionId = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "regenerateTransactionId", from: params, for: funcName)
        self.signers = try JSONRPCParser.getOptionalPrimitiveListIfPresent(name: "signers", from: params, for: funcName)
    }

    // MARK: - Helper Functions

    /// Applies common transaction parameters to a Hiero `Transaction`.
    ///
    /// This method populates standard fields on the given `Transaction` instance using values
    /// parsed from JSON input, including transaction ID, fee, memo, duration, and signer information.
    ///
    /// - Parameters:
    ///   - transaction: The mutable `Transaction` instance to configure.
    /// - Note: If `signers` is present, the transaction is frozen and each provided key is used to sign it.
    internal func fillOutTransaction<T: Transaction>(transaction: inout T) throws {
        // The transaction ID may be the entire transaction ID, or just the account ID of the payer.
        if let transactionId = self.transactionId {
            do {
                transaction.transactionId = try TransactionId.fromString(transactionId)
            } catch {
                // If parsing fails, treat it as an AccountId and generate a TransactionId from it.
                transaction.transactionId = try TransactionId.generateFrom(AccountId.fromString(transactionId))
            }
        
        }

        transaction.maxTransactionFee = self.maxTransactionFee.flatMap { Hbar.fromTinybars($0) }
        transaction.transactionValidDuration = self.validTransactionDuration.flatMap {
            Duration(seconds: toUint64($0))
        }
        transaction.transactionMemo = self.memo ?? transaction.transactionMemo
        transaction.regenerateTransactionId = self.regenerateTransactionId ?? transaction.regenerateTransactionId

        try self.signers.map {
            try transaction.freezeWith(SDKClient.client.getClient())
            try $0.forEach { transaction.sign(try PrivateKey.fromStringDer($0)) }
        }
    }
}
