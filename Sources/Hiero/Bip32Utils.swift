// SPDX-License-Identifier: Apache-2.0

public class Bip32Utils {
    static let hardenedMask: Int32 = 1 << 31

    public init() {}

    /// Harden the index
    public static func toHardenedIndex(_ index: UInt32) -> Int32 {
        let index = Int32(bitPattern: index)

        return (index | hardenedMask)
    }

    /// Check if the index is hardened
    public static func isHardenedIndex(_ index: UInt32) -> Bool {
        let index = Int32(bitPattern: index)

        return (index & hardenedMask) != 0
    }
}
