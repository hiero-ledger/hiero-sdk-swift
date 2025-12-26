// SPDX-License-Identifier: Apache-2.0

/// Utilities for BIP-32 Hierarchical Deterministic (HD) wallet key derivation.
///
/// BIP-32 defines a standard for deriving multiple keys from a single master seed.
/// This enum provides utilities for working with hardened derivation indices.
///
/// ## Hardened vs Non-Hardened Derivation
///
/// - **Non-hardened** (indices 0 to 2^31-1): Child public keys can be derived from parent public keys
/// - **Hardened** (indices 2^31 to 2^32-1): Requires the parent private key for derivation
///
/// Hardened derivation provides better security as compromise of a child key doesn't
/// compromise sibling keys.
///
/// Reference: BIP-32 (https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)

internal enum Bip32Utils {
    /// Bitmask for the hardened index flag (bit 31).
    internal static let hardenedMask: Int32 = 1 << 31

    /// Convert an index to a hardened index.
    ///
    /// Hardened indices have bit 31 set, indicating they require the parent
    /// private key for derivation (cannot derive from public key alone).
    ///
    /// - Parameter index: The base index (0 to 2^31-1).
    /// - Returns: The hardened index with bit 31 set.
    internal static func toHardenedIndex(_ index: UInt32) -> Int32 {
        let index = Int32(bitPattern: index)
        return index | hardenedMask
    }

    /// Check if an index is hardened.
    ///
    /// - Parameter index: The index to check.
    /// - Returns: `true` if the index has bit 31 set (hardened), `false` otherwise.
    internal static func isHardenedIndex(_ index: UInt32) -> Bool {
        let index = Int32(bitPattern: index)
        return (index & hardenedMask) != 0
    }
}
