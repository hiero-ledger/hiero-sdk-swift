// SPDX-License-Identifier: Apache-2.0

import CryptoKit
import Foundation

extension Crypto {
    internal enum Sha2 {
        case sha256
        case sha384
        case sha512

        internal static func digest(_ kind: Sha2, _ data: Data) -> Data {
            kind.digest(data)
        }

        internal func digest(_ data: Data) -> Data {
            switch self {
            case .sha256:
                return Data(CryptoKit.SHA256.hash(data: data))
            case .sha384:
                return Data(CryptoKit.SHA384.hash(data: data))
            case .sha512:
                return Data(CryptoKit.SHA512.hash(data: data))
            }
        }

        /// Hash data using the `sha256` algorithm.
        ///
        /// - Parameter data: the data to be hashed.
        ///
        /// - Returns: the hash of `data`.
        internal static func sha256(_ data: Data) -> Data {
            digest(.sha256, data)
        }

        /// Hash data using the `sha384` algorithm.
        ///
        /// - Parameter data: the data to be hashed.
        ///
        /// - Returns: the hash of `data`.
        internal static func sha384(_ data: Data) -> Data {
            digest(.sha384, data)
        }
    }
}
