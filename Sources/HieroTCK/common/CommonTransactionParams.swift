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

    internal var transactionId: String? = nil
    internal var maxTransactionFee: Int64? = nil
    internal var validTransactionDuration: Int64? = nil
    internal var memo: String? = nil
    internal var regenerateTransactionId: Bool? = nil
    internal var signers: [String]? = nil

    internal init(from parameters: [String: JSONObject]?, for method: JSONRPCMethod) throws {
        guard let params = parameters else { return }

        self.transactionId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "transactionId",
            from: params,
            for: method)
        self.maxTransactionFee = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "maxTransactionFee",
            from: params,
            for: method)
        self.validTransactionDuration = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "validTransactionDuration",
            from: params,
            for: method)
        self.memo = try JSONRPCParser.getOptionalParameterIfPresent(name: "memo", from: params, for: method)
        self.regenerateTransactionId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "regenerateTransactionId",
            from: params,
            for: method)
        self.signers = try JSONRPCParser.getOptionalPrimitiveListIfPresent(name: "signers", from: params, for: method)
    }

    /// Applies common transaction parameters to a Hiero `Transaction`.
    ///
    /// This method populates standard fields on the given `Transaction` instance using values
    /// parsed from JSON input, including transaction ID, fee, memo, duration, and signer information.
    ///
    /// - Parameters:
    ///   - transaction: The mutable `Transaction` instance to configure.
    /// - Note: If `signers` is present, the transaction is frozen and each provided key is used to sign it.
    internal func applyToTransaction<T: Transaction>(_ tx: inout T) throws {
        // The transaction ID may be the entire transaction ID, or just the account ID of the payer.
        if let transactionId = self.transactionId {
            do {
                tx.transactionId = try TransactionId.fromString(transactionId)
            } catch {
                // If parsing fails, treat it as an AccountId and generate a TransactionId from it.
                tx.transactionId = try TransactionId.generateFrom(AccountId.fromString(transactionId))
            }
        }

        tx.maxTransactionFee = self.maxTransactionFee.flatMap { Hbar.fromTinybars($0) }
        tx.transactionValidDuration = self.validTransactionDuration.flatMap {
            Duration(seconds: UInt64(bitPattern: $0))
        }
        self.memo.assign(to: &tx.transactionMemo)
        tx.regenerateTransactionId = self.regenerateTransactionId

        try self.signers.map {
            try SDKClient.client.freezeTransaction(&tx)
            try $0.forEach { tx.sign(try PrivateKey.fromStringDer($0)) }
        }
    }
}
