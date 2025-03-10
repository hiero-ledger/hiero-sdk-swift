// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct TransactionHash: CustomStringConvertible {
    internal init(hashing data: Data) {
        self.data = Crypto.Sha2.sha384(data)
    }

    public let data: Data

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
