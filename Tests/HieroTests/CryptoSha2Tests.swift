// SPDX-License-Identifier: Apache-2.0

import XCTest

@testable import Hiero

internal final class CryptoSha2Tests: XCTestCase {
    internal func testSha256Hash() throws {
        let input = "testingSha256".data(using: .utf8)!

        let sha = CryptoNamespace.Sha2.sha256(input)

        XCTAssertEqual(sha.hexStringEncoded(), "635cd23293b70af14655d9de9b84c403ab2668d5acd0bd38b5c8e79b50e5992a")
        XCTAssertEqual(sha.count, 32)
    }

    internal func testSha384Hash() throws {
        let input = "testingSha384".data(using: .utf8)!

        let sha = CryptoNamespace.Sha2.sha384(input)

        XCTAssertEqual(
            sha.hexStringEncoded(),
            "3192e2d18a6cbf87971dffb52cf5661f3eab1a682a41e878108a83e87f7621dcb0dc45bca09776db710ac5806272414e")
        XCTAssertEqual(sha.count, 48)
    }

    internal func testSha256HashDigest() throws {
        let input = "testingSha256digest".data(using: .utf8)!

        let sha = CryptoNamespace.Sha2.digest(CryptoNamespace.Sha2.sha256, input)

        XCTAssertEqual(
            sha.hexStringEncoded(),
            "c06923f6c6b92625b9e1822930ddda782f2602f55a90b7c621ab8ac6e30e1655")
        XCTAssertEqual(sha.count, 32)
    }

    internal func testSha384HashDigest() throws {
        let input = "testingSha384digest".data(using: .utf8)!

        let sha = CryptoNamespace.Sha2.digest(CryptoNamespace.Sha2.sha384, input)

        XCTAssertEqual(
            sha.hexStringEncoded(),
            "093efec585a6221172036f291263eede21b43e3240976320a2232d728ca9f9b16a0927260493b6310a761e913441ed10")
        XCTAssertEqual(sha.count, 48)
    }

    internal func testSha512HashDigest() throws {
        let input = "testingSha512digest".data(using: .utf8)!

        let sha = CryptoNamespace.Sha2.digest(CryptoNamespace.Sha2.sha512, input)

        XCTAssertEqual(
            sha.hexStringEncoded(),
            "6e96845f64768cca16294f269bfcdd086afc942e072ab952c33ad90c782182fa260db70978d8306abedbf7d91979f0e8d2d65a1c53e4b36dfbd98707939e32d7"
        )
        XCTAssertEqual(sha.count, 64)
    }
}
