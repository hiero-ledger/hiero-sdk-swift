// SPDX-License-Identifier: Apache-2.0

import Foundation

/// A cryptographic hash of a transaction, used to uniquely identify transactions
/// on the Hiero network.
///
/// `TransactionHash` is computed using SHA-384 hashing and provides a way to
/// reference and verify transactions after they have been submitted.
///
/// ## Example Usage
/// ```swift
/// // Transaction hashes are typically obtained from transaction responses
/// let response = try await transaction.execute(client)
/// let hash = response.transactionHash
///
/// // Convert to hex string for display or logging
/// print("Transaction hash: \(hash)")
/// ```
public struct TransactionHash: CustomStringConvertible {
    /// Creates a new transaction hash by computing the SHA-384 hash of the provided data.
    ///
    /// - Parameter data: The transaction data to hash.
    internal init(hashing data: Data) {
        self.data = Sha2.sha384(data)
    }

    /// The raw bytes of the SHA-384 hash.
    public let data: Data

    /// A hexadecimal string representation of the transaction hash.
    ///
    /// This is useful for displaying the hash in logs, UIs, or when comparing
    /// transaction hashes as strings.
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
