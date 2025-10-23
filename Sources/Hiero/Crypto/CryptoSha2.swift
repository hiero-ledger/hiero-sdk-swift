// SPDX-License-Identifier: Apache-2.0

import Foundation

#if canImport(Crypto)
    // Prefer Swift Crypto (cross-platform)
    import Crypto
#elseif canImport(CryptoKit)
    // Fallback to Apple CryptoKit (Darwin only)
    import CryptoKit
#endif

extension CryptoNamespace {
    internal enum Sha2 {
        case sha256
        case sha384
        case sha512

        @inline(__always)
        internal static func digest(_ kind: Sha2, _ data: Data) -> Data {
            kind.digest(data)
        }

        internal func digest(_ data: Data) -> Data {
            switch self {
            case .sha256:
                #if canImport(Crypto)
                    return Data(SHA256.hash(data: data))
                #else
                    return Data(CryptoKit.SHA256.hash(data: data))
                #endif

            case .sha384:
                #if canImport(Crypto)
                    return Data(SHA384.hash(data: data))
                #else
                    return Data(CryptoKit.SHA384.hash(data: data))
                #endif

            case .sha512:
                #if canImport(Crypto)
                    return Data(SHA512.hash(data: data))
                #else
                    return Data(CryptoKit.SHA512.hash(data: data))
                #endif
            }
        }

        /// Hash data using the `sha256` algorithm.
        internal static func sha256(_ data: Data) -> Data {
            digest(.sha256, data)
        }

        /// Hash data using the `sha384` algorithm.
        internal static func sha384(_ data: Data) -> Data {
            digest(.sha384, data)
        }

        /// Hash data using the `sha512` algorithm.
        internal static func sha512(_ data: Data) -> Data {
            digest(.sha512, data)
        }
    }
}
