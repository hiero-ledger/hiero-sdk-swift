// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The public struct that represents the SHA-384 hash of a transaction. It is used to uniquely identify the transaction.
public struct TransactionHash: CustomStringConvertible {
    /// Computes a SHA-384 cryptographic hash of the input data.
    internal init(hashing data: Data) {
        self.data = Sha2.sha384(data)
    }

    /// Stores the raw hash value.
    public let data: Data

    /// Returns the hash value converted to a hexadecimal string.
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
