// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SwiftASN1
import XCTest

@testable import Hiero

internal final class CryptoAesUnitTests: HieroUnitTestCase {
    internal static var testPassphrase = "testpassphrase13d14"

    internal func test_AesDecryption() throws {
        let bytesDer = PrivateKey.toBytesDer(TestConstants.privateKey)
        let iv = Data(hexEncoded: "0046A9EED8D16BE8BD6F0CAA6A197CE8")!

        var hash = MD5Hasher()

        hash.update(data: Self.testPassphrase.data(using: .utf8)!)
        hash.update(data: iv[slicing: ..<8]!)

        let password = Data(hash.finalize().bytes)

        let decrypted = try Aes.aes128CbcPadDecrypt(key: password, iv: iv, message: bytesDer())

        XCTAssertEqual(
            decrypted.hexStringEncoded(),
            "d8ea1c72c322bc67ad533333a0b1a9e2215e34e466c913bed40c5a301a3f7fa9d376b475781c326b91e02599dc7a4412"
        )
    }
}
