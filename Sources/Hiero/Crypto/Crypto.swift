// SPDX-License-Identifier: Apache-2.0

// used as a namespace
internal enum Crypto {}

extension Crypto {
    internal enum Hmac {
        // case sha1
        case sha2(Crypto.Sha2)
    }
}
