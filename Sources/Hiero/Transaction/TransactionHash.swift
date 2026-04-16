// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The SHA-384 hash of a transaction, used to uniquely identify transactions on the network.
public struct TransactionHash: CustomStringConvertible {
    /// Creates a transaction hash by computing SHA-384 of the given data.
    internal init(hashing data: Data) {
        self.data = Sha2.sha384(data)
    }

    /// The raw bytes of the SHA-384 hash.
    public let data: Data

    /// Returns the hash as a hex-encoded string.
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
