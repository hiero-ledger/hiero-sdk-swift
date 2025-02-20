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

private func keyWithChain(key: PrivateKey, chainCode: String) -> PrivateKey {
    key.withChainCode(chainCode: Data(hexEncoded: chainCode)!)
}

internal final class PrivateKeyTests: XCTestCase {
    internal func testParseEd25519() throws {
        let privateKey: PrivateKey =
            "302e020100300506032b65700422042098aa82d6125b5efa04bf8372be7931d05cd77f5ef3330b97d6ee7c006eaaf312"

        XCTAssertEqual(
            privateKey.description,
            "302e020100300506032b65700422042098aa82d6125b5efa04bf8372be7931d05cd77f5ef3330b97d6ee7c006eaaf312")
    }

    internal func testParseEd25519WithPublicKey() throws {
        let privateKey = try PrivateKey.fromString(
            "3053020101300506032b65700422042092a736a341feb460a3906dec5b7eeaaf64111e6d9769e06b543986968465802fa123032100b8485a5584725595e5b856f8b361ed84571ccb58e00447b307f9df608acef1f7"
        )
        XCTAssertEqual(
            privateKey.description,
            "302e020100300506032b65700422042092a736a341feb460a3906dec5b7eeaaf64111e6d9769e06b543986968465802f")
    }

    internal func testParseEcdsa() throws {
        let privateKey: PrivateKey =
            "3030020100300706052b8104000a042204208776c6b831a1b61ac10dac0304a2843de4716f54b1919bb91a2685d0fe3f3048"

        XCTAssertEqual(
            privateKey.description,
            "3030020100300706052b8104000a042204208776c6b831a1b61ac10dac0304a2843de4716f54b1919bb91a2685d0fe3f3048")
    }

    internal func testEd25519Sign() throws {
        let message = "hello, world".data(using: .utf8)!
        let privateKey: PrivateKey =
            "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e10"

        let signature = privateKey.sign(message)

        // note that CryptoKit randomizes the signature, *sigh*, so the only thing we *can* test is that the signature verifies.

        XCTAssertNoThrow(try privateKey.publicKey.verify(message, signature))
    }

    internal func testEcdsaSign() throws {
        let privateKey: PrivateKey =
            "3030020100300706052b8104000a042204208776c6b831a1b61ac10dac0304a2843de4716f54b1919bb91a2685d0fe3f3048"

        let signature = privateKey.sign("hello world".data(using: .utf8)!)

        XCTAssertEqual(
            signature.hexStringEncoded(),
            "f3a13a555f1f8cd6532716b8f388bd4e9d8ed0b252743e923114c0c6cbfe414c086e3717a6502c3edff6130d34df252fb94b6f662d0cd27e2110903320563851"
        )
    }

    internal func testEd25519LegacyDerive() throws {
        let privateKey: PrivateKey =
            "302e020100300506032b65700422042098aa82d6125b5efa04bf8372be7931d05cd77f5ef3330b97d6ee7c006eaaf312"

        let privateKey0 = try privateKey.legacyDerive(0)

        XCTAssertEqual(
            privateKey0.description,
            "302e020100300506032b6570042204202b7345f302a10c2a6d55bf8b7af40f125ec41d780957826006d30776f0c441fb")

        let privateKeyNeg1 = try privateKey.legacyDerive(-1)

        XCTAssertEqual(
            privateKeyNeg1.description,
            "302e020100300506032b657004220420caffc03fdb9853e6a91a5b3c57a5c0031d164ce1c464dea88f3114786b5199e5")
    }

    internal func testEd25519LegacyDerive2() throws {
        let privateKey: PrivateKey =
            "302e020100300506032b65700422042000c2f59212cb3417f0ee0d38e7bd876810d04f2dd2cb5c2d8f26ff406573f2bd"

        let privateKeyMhw = try privateKey.legacyDerive(0xff_ffff_ffff)

        XCTAssertEqual(
            privateKeyMhw.description,
            "302e020100300506032b6570042204206890dc311754ce9d3fc36bdf83301aa1c8f2556e035a6d0d13c2cccdbbab1242")
    }

    // "iosKey"
    internal func testEd25519Derive1() throws {
        let key = keyWithChain(
            key: "302e020100300506032b657004220420a6b9548d7e123ad4c8bc6fee58301e9b96360000df9d03785c07b620569e7728",
            chainCode: "cde7f535264f1db4e2ded409396f8c72f8075cc43757bd5a205c97699ea40271"
        )

        let child = try key.derive(0)

        XCTAssertEqual(
            child.prettyPrint(),
            #"""
            PrivateKey.ed25519(
                key: 5f66a51931e8c99089472e0d70516b6272b94dd772b967f8221e1077f966dbda,
                chainCode: Optional("0e5c869c1cf9daecd03edb2d49cf2621412578a352578a4bb7ef4eef2942b7c9")
            )
            """#
        )
    }

    // "androidKey"
    internal func testEd25519Derive2() throws {
        let key = keyWithChain(
            key:
                "302e020100300506032b65700422042097dbce1988ef8caf5cf0fd13a5374969e2be5f50650abd19314db6b32f96f18e",
            chainCode: "b7b406314eb2224f172c1907fe39f807e306655e81f2b3bc4766486f42ef1433"
        )

        let child = try key.derive(0)

        XCTAssertEqual(
            child.prettyPrint(),
            #"""
            PrivateKey.ed25519(
                key: c284c25b3a1458b59423bc289e83703b125c8eefec4d5aa1b393c2beb9f2bae6,
                chainCode: Optional("a7a1c2d115a988e51efc12c23692188a4796b312a4a700d6c703e4de4cf1a7f6")
            )
            """#
        )
    }

    internal func testEd25519FromPem() throws {
        let pemString = """
            -----BEGIN PRIVATE KEY-----
            MC4CAQAwBQYDK2VwBCIEINtIS4KOZLLY8SzjwKDpOguMznrxu485yXcyOUSCU44Q
            -----END PRIVATE KEY-----
            """
        let privateKey = try PrivateKey.fromPem(pemString)

        XCTAssertEqual(
            privateKey.description,
            "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e10")
    }

    internal func testEd25519FromPemWithPassword() throws {
        let pemString =
            """
            -----BEGIN ENCRYPTED PRIVATE KEY-----
            MIGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            DAYIKoZIhvcNAgkFADAdBglghkgBZQMEAQIEENfMacg1/Txd/LhKkxZtJe0EQEVL
            mez3xb+sfUIF3TKEIDJtw7H0xBNlbAfLxTV11pofiar0z1/WRBHFFUuGIYSiKjlU
            V9RQhAnemO84zcZfTYs=
            -----END ENCRYPTED PRIVATE KEY-----
            """

        let privateKey = try PrivateKey.fromPem(pemString, "test")

        XCTAssertEqual(
            privateKey.description,
            "302e020100300506032b6570042204208d8df406a762e36dfbf6dda2239f38a266db369e09bca6a8569e9e79b4826152"
        )
    }

    internal func testEcdsaFromPem() throws {
        let pemString = """
            -----BEGIN PRIVATE KEY-----
            MDACAQAwBwYFK4EEAAoEIgQgh3bGuDGhthrBDawDBKKEPeRxb1SxkZu5GiaF0P4/
            MEg=
            -----END PRIVATE KEY-----
            """

        let privateKey = try PrivateKey.fromPem(pemString)

        XCTAssertEqual(
            privateKey.description,
            "3030020100300706052b8104000a042204208776c6b831a1b61ac10dac0304a2843de4716f54b1919bb91a2685d0fe3f3048")
    }

    internal func testEd25519FromPemInvalidTypeLabel() {
        // extra `S` in the type label
        let pemString = """
            -----BEGIN PRIVATE KEYS-----
            MC4CAQAwBQYDK2VwBCIEINtIS4KOZLLY8SzjwKDpOguMznrxu485yXcyOUSCU44Q
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try PrivateKey.fromPem(pemString)) { error in
            XCTAssertEqual((error as? HError)?.kind, HError.ErrorKind.keyParse)
        }
    }

    internal func testEd25519Pkcs8UnencryptedPem() throws {
        let s = """
            -----BEGIN PRIVATE KEY-----
            MC4CAQAwBQYDK2VwBCIEIOgbjaHgEqF7PY0t2dUf2VU0u1MRoKii/fywDlze4lvl
            -----END PRIVATE KEY-----
            """

        let pk = try PrivateKey.fromPem(s)

        XCTAssert(pk.isEd25519())
        XCTAssertEqual(
            pk.toStringRaw(),
            "e81b8da1e012a17b3d8d2dd9d51fd95534bb5311a0a8a2fdfcb00e5cdee25be5"
        )
        XCTAssertEqual(
            pk.publicKey.toStringRaw(),
            "f7b9aa4a8e4eee94e4277dfe757d8d7cde027e7cd5349b7d8e6ee21c9b9395be"
        )
    }

    internal func testEcdsaEcUnencryptedUncompressedPem() throws {
        let s = """
            -----BEGIN EC PRIVATE KEY-----
            MHQCAQEEIG8I+jKi+iGVa7ttbfnlnML5AdvPugbgBWnseYjrle6qoAcGBSuBBAAK
            oUQDQgAEqf5BmMeBzkU1Ra9UAbZJo3tytVOlb7erTc36LRLP20mOLU7+mFY+3Cfe
            fAZgBtPXRAmDtRvYGODswAalW85GKA==
            -----END EC PRIVATE KEY-----
            """

        let pk = try PrivateKey.fromPem(s)

        XCTAssert(pk.isEcdsa())
        XCTAssertEqual(
            pk.toStringRaw(),
            "6f08fa32a2fa21956bbb6d6df9e59cc2f901dbcfba06e00569ec7988eb95eeaa"
        )
        XCTAssertEqual(
            pk.publicKey.toStringRaw(),
            "02a9fe4198c781ce453545af5401b649a37b72b553a56fb7ab4dcdfa2d12cfdb49"
        )
    }

    internal func testEcdsaEcUnencryptedCompressedPem() throws {
        let s = """
            -----BEGIN EC PRIVATE KEY-----
            MFQCAQEEIOHyhclwHbha3f281Kvd884rhBzltxGJxCZyaQCagH9joAcGBSuBBAAK
            oSQDIgACREr6gFZa4K7hBP+bA25VdgQ+0ABFgM+g5RYw/W6T1Og=
            -----END EC PRIVATE KEY-----
            """
        let pk = try PrivateKey.fromPem(s)

        XCTAssert(pk.isEcdsa())
        XCTAssertEqual(
            pk.toStringRaw(),
            "e1f285c9701db85addfdbcd4abddf3ce2b841ce5b71189c4267269009a807f63"
        )
        XCTAssertEqual(
            pk.publicKey.toStringRaw(),
            "02444afa80565ae0aee104ff9b036e5576043ed0004580cfa0e51630fd6e93d4e8"
        )
    }

    internal func testEd25519Pkcs8EncryptedPem() throws {
        let s = """
            -----BEGIN ENCRYPTED PRIVATE KEY-----
            MIGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAiho4GvPxvL6wICCAAw
            DAYIKoZIhvcNAgkFADAdBglghkgBZQMEAQIEEIdsubXR0QvxXGSprqDuDXwEQJZl
            OBtwm2p2P7WrWE0OnjGxUe24fWwdrvJUuguFtH3FVWc8C5Jbxgbyxsuzbf+utNL6
            0ey+WdbGL06Bw0HGqs8=
            -----END ENCRYPTED PRIVATE KEY-----
            """
        let pk = try PrivateKey.fromPem(s, "asdasd123")

        XCTAssert(pk.isEd25519())
        XCTAssertEqual(
            pk.toStringRaw(),
            "fa0857e963946d5f5e035684c40354d3cd3dcc80c0fb77beac2ef7c4b5271599"
        )
        XCTAssertEqual(
            pk.publicKey.toStringRaw(),
            "202af61e141465d4bf2c356d37d18bd026c246bde4eb73258722ad11f790be4e"
        )
    }

    internal func testEcdsaEcEncryptedUncompressedPem() throws {
        let s = """
            -----BEGIN EC PRIVATE KEY-----
            Proc-Type: 4,ENCRYPTED
            DEK-Info: AES-128-CBC,0046A9EED8D16F0CAA66A197CE8BE8BD

            9VU9gReUmrn4XywjMx0F0A3oGzpHIksEXma72TCSdcxI7zHy0mtzuGq4Wd25O38s
            H9c6kvhTPS1N/c6iNhx154B0HUoND8jvAvfxbGR/R87vpZJsOoKCmRxGqrxG8HER
            FIHQ1jy16DrAbU95kDyLsiF1dy2vUY/HoqFZwxl/IVc=
            -----END EC PRIVATE KEY-----
            """

        let pk = try PrivateKey.fromPem(s, "asdasd123")

        XCTAssert(pk.isEcdsa())
        XCTAssertEqual(
            pk.toStringRaw(),
            "cf49eb5206c1b0468854d6ea7b370590619625514f71ff93608a18465e4012ad"
        )
        XCTAssertEqual(
            pk.publicKey.toStringRaw(),
            "025f0d14a7562d6319e5b8f91620d2ce9ad13d9abf21cfe9bd0a092c0f35bf1701"
        )
    }

    internal func testEcdsaEcEncryptedCompressedPem() throws {
        let s = """
            -----BEGIN EC PRIVATE KEY-----
            Proc-Type: 4,ENCRYPTED
            DEK-Info: AES-128-CBC,4A9B3B987EC2EFFA405818327D14FFF7

            Wh756RkK5fn1Ke2denR1OYfqE9Kr4BXhgrEMTU/6o0SNhMULUhWGHrCWvmNeEQwp
            ZVZYUxgYoTlJBeREzKAZithcvxIcTbQfLABo1NZbjA6YKqAqlGpM6owwL/f9e2ST
            -----END EC PRIVATE KEY-----
            """

        let pk = try PrivateKey.fromPem(s, "asdasd123")

        XCTAssert(pk.isEcdsa())
        XCTAssertEqual(
            pk.toStringRaw(),
            "c0d3e16ba5a1abbeac4cd327a3c3c1cc10438431d0bac019054e573e67768bb5"
        )
        XCTAssertEqual(
            pk.publicKey.toStringRaw(),
            "02065f736378134c53c7a2ee46f199fb93b9b32337be4e95660677046476995544"
        )
    }

    internal func testEd25519Pkcs8DerPrivateKey() throws {
        let s = "302e020100300506032b657004220420feb858a4a69600a5eef2d9c76f7fb84fc0b6627f29e0ab17e160f640c267d404"

        let pk = try PrivateKey.fromStringDer(s)

        XCTAssert(pk.isEd25519())
        XCTAssertEqual(
            pk.toStringRaw(),
            "feb858a4a69600a5eef2d9c76f7fb84fc0b6627f29e0ab17e160f640c267d404"
        )
        XCTAssertEqual(
            pk.publicKey.toStringRaw(),
            "8ccd31b53d1835b467aac795dab19b274dd3b37e3daf12fcec6bc02bac87b53d"
        )
    }

    internal func testEcdsaEcPrivateKeyCompressedDer() throws {
        let s =
            "30540201010420ac318ea8ff8d991ab2f16172b4738e74dc35a56681199cfb1c0cb2e7cb560ffda00706052b8104000aa124032200036843f5cb338bbb4cdb21b0da4ea739d910951d6e8a5f703d313efe31afe788f4"

        let pk = try PrivateKey.fromStringDer(s)

        XCTAssert(pk.isEcdsa())
        XCTAssertEqual(
            pk.toStringRaw(),
            "ac318ea8ff8d991ab2f16172b4738e74dc35a56681199cfb1c0cb2e7cb560ffd"
        )
        XCTAssertEqual(
            pk.publicKey.toStringRaw(),
            "036843f5cb338bbb4cdb21b0da4ea739d910951d6e8a5f703d313efe31afe788f4"
        )
    }

    internal func testEcdsaEcPrivateKeyUncompressedDer() throws {
        let s =
            "307402010104208927647ad12b29646a1d051da8453462937bb2c813c6815cac6c0b720526ffc6a00706052b8104000aa14403420004aaac1c3ac1bea0245b8e00ce1e2018f9eab61b6331fbef7266f2287750a6597795f855ddcad2377e22259d1fcb4e0f1d35e8f2056300c15070bcbfce3759cc9d"

        let pk = try PrivateKey.fromStringDer(s)

        XCTAssert(pk.isEcdsa())
        XCTAssertEqual(pk.toStringRaw(), "8927647ad12b29646a1d051da8453462937bb2c813c6815cac6c0b720526ffc6")

        XCTAssertEqual(
            pk.publicKey.toStringRaw(),
            "03aaac1c3ac1bea0245b8e00ce1e2018f9eab61b6331fbef7266f2287750a65977"
        )
    }

    internal func testEcdsaEcPrivateKeyNoPublicKeyDer() throws {
        let s = "302e0201010420a6170a6aa6389a5bd3a3a8f9375f57bd91aa7f7d8b8b46ce0b702e000a21a5fea00706052b8104000a"

        let pk = try PrivateKey.fromStringDer(s)

        XCTAssert(pk.isEcdsa())
        XCTAssertEqual(
            pk.toStringRaw(),
            "a6170a6aa6389a5bd3a3a8f9375f57bd91aa7f7d8b8b46ce0b702e000a21a5fe"
        )
        XCTAssertEqual(
            pk.publicKey.toStringRaw(),
            "03b69a75a5ddb1c0747e995d47555019e5d8a28003ab5202bd92f534361fb4ec8a"
        )
    }

    internal func testslip10TestVector1() throws {
        let chainCode1 = "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"
        let privateKey1 = "e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35"
        let publicKey1 = "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"

        let seed = Data(hexEncoded: "000102030405060708090a0b0c0d0e0f")!

        let key1 = PrivateKey.fromSeedECDSAsecp256k1(seed)
        XCTAssertEqual(key1.chainCode?.data.hexStringEncoded(), chainCode1)
        XCTAssertEqual(key1.toStringRaw(), privateKey1)
        XCTAssert(publicKey1.contains(key1.publicKey.toStringRaw()))

    }
}
