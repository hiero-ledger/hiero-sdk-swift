// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The SHA-384 hash of a transaction, used to uniquely identify transactions on the Hiero network.
///
/// A transaction hash is computed from the transaction's serialized bytes and can be used to:
/// - Track the status of a submitted transaction
/// - Reference a specific transaction in queries and receipts
/// - Verify that a transaction has not been modified
///
/// ## Example
/// ```swift
/// let transaction = TransferTransaction()
///     .hbarTransfer(sender, Hbar.fromTinybars(-100))
///     .hbarTransfer(receiver, Hbar.fromTinybars(100))
///
/// let response = try await transaction.execute(client)
/// let hash = response.transactionHash
/// print("Transaction hash: \(hash)")  // Prints hex-encoded hash
/// ```
public struct TransactionHash: CustomStringConvertible {
    /// Creates a transaction hash by computing the SHA-384 hash of the given data.
    ///
    /// - Parameter data: The serialized transaction bytes to hash.
    internal init(hashing data: Data) {
        self.data = Sha2.sha384(data)
    }

    /// The raw bytes of the SHA-384 hash.
    ///
    /// This is a 48-byte (384-bit) value representing the cryptographic hash
    /// of the transaction.
    public let data: Data

    /// Returns the hash as a lowercase hex-encoded string.
    ///
    /// This is useful for displaying the hash in logs, receipts, or user interfaces.
    /// The returned string will be 96 characters long (2 hex characters per byte).
    public var description: String {
        data.hexStringEncoded()
    }
}

#if compiler(<5.7)
    // Swift 5.7 added the conformance to data, despite to the best of my knowledge, not changing anything in the underlying type.
    extension TransactionHash: @unchecked Sendable {}
#else
    extension TransactionHash: Sendable {}
#endif
