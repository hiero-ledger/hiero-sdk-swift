// SPDX-License-Identifier: Apache-2.0

// used as a namespace
internal enum CryptoNamespace {}

extension CryptoNamespace {
    internal enum Hmac {
        // case sha1
        case sha2(CryptoNamespace.Sha2)
    }
}
