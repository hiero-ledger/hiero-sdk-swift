/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import Foundation
import OpenSSL

extension Crypto {
    internal enum Sha3 {
        case keccak256

        internal static func digest(_ kind: Sha3, _ data: Data) -> Data {
            kind.digest(data)
        }

        internal func digest(_ data: Data) -> Data {
            switch self {
            case .keccak256:
                return keccak256Digest(data)
            }
        }

        /// Hash data using the `keccak256` algorithm.
        ///
        /// - Parameter data: the data to be hashed.
        ///
        /// - Returns: the hash of `data`.
        internal static func keccak256(_ data: Data) -> Data {
            digest(.keccak256, data)
        }

        private func keccak256Digest(_ data: Data) -> Data {
            // Initialize OpenSSL's new context
            let ctx = EVP_MD_CTX_new()
            defer { EVP_MD_CTX_free(ctx) }

            // Fetch Keccak-256 Algorithm
            guard let keccak256 = EVP_MD_fetch(nil, "KECCAK-256", nil) else {
                fatalError("Failed to get Keccak-256 digest method")
            }

            guard EVP_DigestInit_ex(ctx, keccak256, nil) == 1 else {
                fatalError("Failed to initialize Keccak-256 context")
            }

            // Feed data into the hashing context
            data.withUnsafeBytes { buffer in
                _ = EVP_DigestUpdate(ctx, buffer.baseAddress, buffer.count)
            }

            // 32 bytes for standard output size
            let hashSize = 32
            var hash = [UInt8](repeating: 0, count: hashSize)

            var length = UInt32(hash.count)
            guard EVP_DigestFinal_ex(ctx, &hash, &length) == 1 else {
                fatalError("Failed to finalize Keccak-256 hash computation")
            }

            return Data(hash)
        }
    }
}
