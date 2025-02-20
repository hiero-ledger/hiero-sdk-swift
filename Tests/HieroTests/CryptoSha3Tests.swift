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

import XCTest

@testable import Hiero

internal final class CryptoSha3Tests: XCTestCase {
    internal func testKeccak256Hash() throws {
        let input = "testingKeccak256".data(using: .utf8)!

        let sha = Crypto.Sha3.keccak256(input)

        XCTAssertEqual(sha.hexStringEncoded(), "e1ab2907c85b96939eba66d57102166b98b590e6d50711473c16886f96ddfe9a")
        XCTAssertEqual(sha.count, 32)
    }

    internal func testKeccak256HashDigest() throws {
        let input = "testingKeccak256Digest".data(using: .utf8)!

        let sha = Crypto.Sha3.digest(Crypto.Sha3.keccak256, input)

        XCTAssertEqual(sha.hexStringEncoded(), "01d49c057038debea7a86616abfd86d76ac9fdfdb15536831d26e94a60d95562")
        XCTAssertEqual(sha.count, 32)
    }
}
