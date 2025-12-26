// SPDX-License-Identifier: Apache-2.0

import Crypto
import Foundation

// MARK: - SHA-2 Hash Functions

/// SHA-2 family of cryptographic hash functions.
///
/// The SHA-2 (Secure Hash Algorithm 2) family includes:
/// - **SHA-256**: 256-bit (32-byte) output
/// - **SHA-384**: 384-bit (48-byte) output
/// - **SHA-512**: 512-bit (64-byte) output
///
/// These are widely used cryptographic hash functions for:
/// - Digital signatures
/// - Message authentication codes (HMAC)
/// - Key derivation functions (KDF)
///
/// ## Example
/// ```swift
/// let hash = Sha2.sha256(data)
/// ```
internal enum Sha2 {
    case sha256
    case sha384
    case sha512

    /// Compute a SHA-2 hash of the given data.
    ///
    /// - Parameters:
    ///   - kind: The SHA-2 variant to use (256, 384, or 512).
    ///   - data: The data to hash.
    /// - Returns: The hash digest as `Data`.
    @inline(__always)
    internal static func digest(_ kind: Sha2, _ data: Data) -> Data {
        kind.digest(data)
    }

    /// Compute the hash digest for this SHA-2 variant.
    ///
    /// - Parameter data: The data to hash.
    /// - Returns: The hash digest (32, 48, or 64 bytes depending on variant).
    internal func digest(_ data: Data) -> Data {
        switch self {
        case .sha256:
            return Data(SHA256.hash(data: data))
        case .sha384:
            return Data(SHA384.hash(data: data))
        case .sha512:
            return Data(SHA512.hash(data: data))
        }
    }

    /// Compute a SHA-256 hash of the given data.
    ///
    /// SHA-256 produces a 32-byte (256-bit) digest.
    ///
    /// - Parameter data: The data to hash.
    /// - Returns: The 32-byte hash digest.
    internal static func sha256(_ data: Data) -> Data {
        digest(.sha256, data)
    }

    /// Compute a SHA-384 hash of the given data.
    ///
    /// SHA-384 produces a 48-byte (384-bit) digest.
    ///
    /// - Parameter data: The data to hash.
    /// - Returns: The 48-byte hash digest.
    internal static func sha384(_ data: Data) -> Data {
        digest(.sha384, data)
    }

    /// Compute a SHA-512 hash of the given data.
    ///
    /// SHA-512 produces a 64-byte (512-bit) digest.
    ///
    /// - Parameter data: The data to hash.
    /// - Returns: The 64-byte hash digest.
    internal static func sha512(_ data: Data) -> Data {
        digest(.sha512, data)
    }
}
