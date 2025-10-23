// SPDX-License-Identifier: Apache-2.0

import CryptoSwift
import Foundation

extension CryptoNamespace {
    internal enum Sha3 {
        case keccak256

        @inline(__always)
        internal static func digest(_ kind: Sha3, _ data: Data) -> Data {
            kind.digest(data)
        }

        internal func digest(_ data: Data) -> Data {
            switch self {
            case .keccak256:
                return keccak256Digest(data)
            }
        }

        /// Hash data using the `keccak256` algorithm (Ethereum-style Keccak, pre-NIST).
        ///
        /// - Parameter data: The bytes to hash.
        /// - Returns: 32-byte Keccak-256 digest.
        @inline(__always)
        internal static func keccak256(_ data: Data) -> Data {
            digest(.keccak256, data)
        }

        // MARK: - Private

        private func keccak256Digest(_ data: Data) -> Data {
            // Use CryptoSwift's SHA3 engine with the Keccak variant.
            // (Some versions don’t expose `Keccak` as a separate type.)
            let bytes = Array(data)
            let out = try! SHA3(variant: .keccak256).calculate(for: bytes)
            return Data(out)
        }
    }
}
