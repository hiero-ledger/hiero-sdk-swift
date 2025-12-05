// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class CryptoSha3UnitTests: HieroUnitTestCase {
    internal func test_Keccak256Hash() throws {
        let input = "testingKeccak256".data(using: .utf8)!

        let sha = CryptoNamespace.Sha3.keccak256(input)

        XCTAssertEqual(sha.hexStringEncoded(), "e1ab2907c85b96939eba66d57102166b98b590e6d50711473c16886f96ddfe9a")
        XCTAssertEqual(sha.count, 32)
    }

    internal func test_Keccak256HashDigest() throws {
        let input = "testingKeccak256Digest".data(using: .utf8)!

        let sha = CryptoNamespace.Sha3.digest(CryptoNamespace.Sha3.keccak256, input)

        XCTAssertEqual(sha.hexStringEncoded(), "01d49c057038debea7a86616abfd86d76ac9fdfdb15536831d26e94a60d95562")
        XCTAssertEqual(sha.count, 32)
    }
}
