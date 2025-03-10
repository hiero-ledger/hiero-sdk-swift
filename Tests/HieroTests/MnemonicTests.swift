// SPDX-License-Identifier: Apache-2.0

import XCTest

@testable import Hiero

private let knownGoodMnemonics: [String] = [
    "inmate flip alley wear offer often piece magnet surge toddler submit right radio absent pear floor belt raven "
        + "price stove replace reduce plate home",
    "tiny denial casual grass skull spare awkward indoor ethics dash enough flavor good daughter early "
        + "hard rug staff capable swallow raise flavor empty angle",
    "ramp april job flavor surround pyramid fish sea good know blame gate village viable include mixed term "
        + "draft among monitor swear swing novel track",
    "evoke rich bicycle fire promote climb zero squeeze little spoil slight damage",
]

internal final class MnemonicTests: XCTestCase {
    internal func testParse() throws {
        for mnemonic in knownGoodMnemonics {
            XCTAssertEqual(try Mnemonic.fromString(mnemonic).description, mnemonic)
        }
    }

    internal func testInvalidLengthError() {
        // we can't test for up to `usize` length, but we can test several lengths to be modestly sure.
        // it might seem that testing many lengths would be slow.
        // we test:

        // todo: this feels overengineered.
        // every length up to (and including `DENSE_LIMIT`).
        // arbitrarily chosen to be 48.

        let denseLimit = 48
        let denseLengths = Array(0...denseLimit)
        let lengths = denseLengths + Array((0...10).lazy.map { $0 * 12 }.drop { $0 < denseLimit })

        for length in lengths.lazy.filter({ ![12, 22, 24].contains($0) }) {
            // this is a word that's explicitly in the word list,
            // to ensure we aren't accidentally testing that this error happens before "word(s) not in list"

            let words = Array(repeating: "apple", count: length)

            XCTAssertThrowsError(try Mnemonic.fromWords(words: words)) { error in
                guard let error = error as? HError,
                    case .mnemonicParse(let reason, _) = error.kind
                else {
                    XCTFail("Unexpected error: \(error)")
                    return
                }

                XCTAssertEqual(reason, .badLength(length))
            }
        }
    }

    internal func testUnknownWords1() {
        let mnemonic = "obvious favorite remain caution remove laptop base vacant alone fever slush dune"

        for index in 0..<12 {
            var words = mnemonic.split(separator: " ").map(String.init)

            words[index] = "lorum"

            XCTAssertThrowsError(try Mnemonic.fromWords(words: words)) { error in
                guard let error = error as? HError,
                    case .mnemonicParse(let reason, _) = error.kind
                else {
                    XCTFail("Unexpected error: \(error)")
                    return
                }

                XCTAssertEqual(reason, .unknownWords([index]))
            }
        }
    }

    internal func testUnknownWords2() {
        // a 24 word mnemonic containing the following typos:
        // absorb -> adsorb
        // account -> acount
        // acquire -> acquired
        let mnemonic =
            "abandon ability able about above absent adsorb abstract absurd abuse access accident "
            + "acount accuse achieve acid acoustic acquired across act action actor actress actual"

        XCTAssertThrowsError(try Mnemonic.fromString(mnemonic)) { error in
            guard let error = error as? HError,
                case .mnemonicParse(let reason, _) = error.kind
            else {
                XCTFail("Unexpected error: \(error)")
                return
            }

            XCTAssertEqual(reason, .unknownWords([6, 12, 17]))
        }
    }

    internal func testChecksumMismatch1() {
        let mnemonic =
            "abandon ability able about above absent absorb abstract absurd abuse access accident "
            + "account accuse achieve acid acoustic acquire across act action actor actress actual"

        XCTAssertThrowsError(try Mnemonic.fromString(mnemonic)) { error in
            guard let error = error as? HError,
                case .mnemonicParse(let reason, _) = error.kind
            else {
                XCTFail("Unexpected error: \(error)")
                return
            }

            XCTAssertEqual(reason, .checksumMismatch(expected: 0xba, actual: 0x17))
        }
    }

    internal func testChecksumMismatch2() {
        let mnemonic = "abandon ability able about above absent absorb abstract absurd abuse access accident"

        XCTAssertThrowsError(try Mnemonic.fromString(mnemonic)) { error in
            guard let error = error as? HError,
                case .mnemonicParse(let reason, _) = error.kind
            else {
                XCTFail("Unexpected error: \(error)")
                return
            }

            XCTAssertEqual(reason, .checksumMismatch(expected: 0x10, actual: 0xb0))
        }
    }

    internal func testFromEntropy() throws {
        let entropy = [
            Data(hexEncoded: "744b201a7c399733691c2fda5c6f605ceb0c016882cb14f64ea9eb5b6d68298b")!,
            Data(hexEncoded: "e2674c8eb2fcada0c433984da6f52bac56466f914b49bd1a8087ed8b12b15248")!,
            Data(hexEncoded: "b1615de02c5da95e15ee0f646f7c5cb02f41e69c9c71df683c1fc78db9b825c7")!,
            Data(hexEncoded: "4e172857ab9ac2563fee9c829a4b2e9b")!,
        ]

        for (entropy, string) in zip(entropy, knownGoodMnemonics) {
            let mnemonic = Mnemonic.fromEntropyForTesting(entropy: entropy)

            XCTAssertEqual(String(describing: mnemonic), string)
        }
    }

    internal func testMnemonic3() throws {
        let str =
            "obvious favorite remain caution remove laptop base vacant increase video erase pass "
            + "sniff sausage knock grid argue salt romance way alone fever slush dune"

        let mnemonic = try Mnemonic.fromString(str)

        let privateKey = try mnemonic.toLegacyPrivateKey()

        XCTAssertEqual(
            privateKey.description,
            "302e020100300506032b65700422042098aa82d6125b5efa04bf8372be7931d05cd77f5ef3330b97d6ee7c006eaaf312"
        )
    }

    internal func testLegacyMnemonic() throws {
        let str =
            "jolly kidnap tom lawn drunk chick optic lust mutter mole bride "
            + "galley dense member sage neural widow decide curb aboard margin manure"

        let mnemonic = try Mnemonic.fromString(str)
        let privateKey = try mnemonic.toLegacyPrivateKey()

        // skip the derives and just test the key.
        // (bugs in `legacy_derive` shouldn't make this function fail.)
        XCTAssertEqual(
            privateKey.description,
            "302e020100300506032b65700422042000c2f59212cb3417f0ee0d38e7bd876810d04f2dd2cb5c2d8f26ff406573f2bd"
        )
    }

    internal func testToPrivateKey() throws {
        let str =
            "inmate flip alley wear offer often " + "piece magnet surge toddler submit right "
            + "radio absent pear floor belt raven " + "price stove replace reduce plate home"

        let mnemonic = try Mnemonic.fromString(str)

        let key = try mnemonic.toPrivateKey()

        XCTAssertEqual(
            key.description,
            "302e020100300506032b657004220420853f15aecd22706b105da1d709b4ac05b4906170c2b9c7495dff9af49e1391da"
        )
    }

    internal func testToStandardECDSAsecp256k1PrivateKey() throws {
        let chainCode = "7717bc71194c257d4b233e16cf48c24adef630052f874a262d19aeb2b527620d"
        let privateKey = "0fde7bfd57ae6ec310bdd8b95967d98e8762a2c02da6f694b152cf9860860ab8"
        let publicKey = "03b1c064b4d04d52e51f6c8e8bb1bff75d62fa7b1446412d5901d424f6aedd6fd4"

        let chainCode2 = "0ff552587f6baef1f0818136bacac0bb37236473f6ecb5a8c1cc68a716726ed1"
        let privateKey2 = "6df5ed217cf6d5586fdf9c69d39c843eb9d152ca19d3e41f7bab483e62f6ac25"
        let publicKey2 = "0357d69bb36fee569838fe7b325c07ca511e8c1b222873cde93fc6bb541eb7ecea"

        let chainCode3 = "e54254940db58ef4913a377062ac6e411daebf435ad592d262d5a66d808a8b94"
        let privateKey3 = "60cb2496a623e1201d4e0e7ce5da3833cd4ec7d6c2c06bce2bcbcbc9dfef22d6"
        let publicKey3 = "02b59f348a6b69bd97afa80115e2d5331749b3c89c61297255430c487d6677f404"

        let chainCode4 = "e333da4bd9e21b5dbd2b0f6d88bad02f0fa24cf4b70b2fb613368d0364cdf8af"
        let privateKey4 = "aab7d720a32c2d1ea6123f58b074c865bb07f6c621f14cb012f66c08e64996bb"
        let publicKey4 = "03a0ea31bb3562f8a309b1436bc4b2f537301778e8a5e12b68cec26052f567a235"

        let chainCode5 = "cb23165e9d2d798c85effddc901a248a1a273fab2a56fe7976df97b016e7bb77"
        let privateKey5 = "100477c333028c8849250035be2a0a166a347a5074a8a727bce1db1c65181a50"
        let publicKey5 = "03d10ebfa2d8ff2cd34aa96e5ef59ca2e69316b4c0996e6d5f54b6932fe51be560"

        // 24 word string Mnemonic
        let mnemonic = try Mnemonic.fromString(knownGoodMnemonics[0])

        // Chain m/44'/3030'/0'/0/0
        let key = try mnemonic.toStandardECDSAsecp256k1PrivateKey("", 0)
        XCTAssertEqual(key.chainCode!.data.hexStringEncoded(), chainCode)
        XCTAssertEqual(key.toStringRaw(), privateKey)
        XCTAssert(publicKey.contains(key.publicKey.toStringRaw()))

        // Chain m/44'/3030'/0'/0/0; Passphrase "some pass"
        let key2 = try mnemonic.toStandardECDSAsecp256k1PrivateKey("some pass", 0)
        XCTAssertEqual(key2.chainCode!.data.hexStringEncoded(), chainCode2)
        XCTAssertEqual(key2.toStringRaw(), privateKey2)
        XCTAssert(publicKey2.contains(key2.publicKey.toStringRaw()))

        // Chain m/44'/3030'/0'/0/2147483647; Passphrase "some pass"
        let key3 = try mnemonic.toStandardECDSAsecp256k1PrivateKey("some pass", 2_147_483_647)
        XCTAssertEqual(key3.chainCode!.data.hexStringEncoded(), chainCode3)
        XCTAssertEqual(key3.toStringRaw(), privateKey3)
        XCTAssert(publicKey3.contains(key3.publicKey.toStringRaw()))

        // Chain m/44'/3030'/0'/0/0'
        let key4 = try mnemonic.toStandardECDSAsecp256k1PrivateKey("", Bip32Utils.toHardenedIndex(0))
        XCTAssertEqual(key4.chainCode!.data.hexStringEncoded(), chainCode4)
        XCTAssertEqual(key4.toStringRaw(), privateKey4)
        XCTAssert(publicKey4.contains(key4.publicKey.toStringRaw()))

        // Chain m/44'/3030'/0'/0/2147483647'; Passphrase "some pass"
        let key5 = try mnemonic.toStandardECDSAsecp256k1PrivateKey(
            "some pass", Bip32Utils.toHardenedIndex(2_147_483_647))
        XCTAssertEqual(key5.chainCode!.data.hexStringEncoded(), chainCode5)
        XCTAssertEqual(key5.toStringRaw(), privateKey5)
        XCTAssert(publicKey5.contains(key5.publicKey.toStringRaw()))
    }

    internal func testToStandardECDSAsecp256k1PrivateKey2() throws {
        let chainCode = "e76e0480faf2790e62dc1a7bac9dce51db1b3571fd74d8e264abc0d240a55d09"
        let privateKey = "f033824c20dd9949ad7a4440f67120ee02a826559ed5884077361d69b2ad51dd"
        let publicKey = "0294bf84a54806989a74ca4b76291d386914610b40b610d303162b9e495bc06416"

        let chainCode2 = "911a1095b64b01f7f3a06198df3d618654e5ed65862b211997c67515e3167892"
        let privateKey2 = "c139ebb363d7f441ccbdd7f58883809ec0cc3ee7a122ef67974eec8534de65e8"
        let publicKey2 = "0293bdb1507a26542ed9c1ec42afe959cf8b34f39daab4bf842cdac5fa36d50ef7"

        let chainCode3 = "a7250c2b07b368a054f5c91e6a3dbe6ca3bbe01eb0489fe8778304bd0a19c711"
        let privateKey3 = "2583170ee745191d2bb83474b1de41a1621c47f6e23db3f2bf413a1acb5709e4"
        let publicKey3 = "03f9eb27cc73f751e8e476dd1db79037a7df2c749fa75b6cc6951031370d2f95a5"

        let chainCode4 = "60c39c6a77bd68c0aaabfe2f4711dc9c2247214c4f4dae15ad4cb76905f5f544"
        let privateKey4 = "962f549dafe2d9c8091ac918cb4fc348ab0767353f37501067897efbc84e7651"
        let publicKey4 = "027123855357fd41d28130fbc59053192b771800d28ef47319ef277a1a032af78f"

        let chainCode5 = "66a1175e7690e3714d53ffce16ee6bb4eb02065516be2c2ad6bf6c9df81ec394"
        let privateKey5 = "f2d008cd7349bdab19ed85b523ba218048f35ca141a3ecbc66377ad50819e961"
        let publicKey5 = "027b653d04958d4bf83dd913a9379b4f9a1a1e64025a691830a67383bc3157c044"

        let str =
            "finish furnace tomorrow wine mass goose festival air palm easy region guilt"

        // 12 word string Mnemonic
        let mnemonic = try Mnemonic.fromString(str)

        // Chain m/44'/3030'/0'/0 /0
        let key = try mnemonic.toStandardECDSAsecp256k1PrivateKey("", 0)
        XCTAssertEqual(key.chainCode!.data.hexStringEncoded(), chainCode)
        XCTAssertEqual(key.toStringRaw(), privateKey)
        XCTAssert(publicKey.contains(key.publicKey.toStringRaw()))

        // Chain m/44'/3030'/0'/0 /0; Passphrase "some pass"
        let key2 = try mnemonic.toStandardECDSAsecp256k1PrivateKey("some pass", 0)
        XCTAssertEqual(key2.chainCode!.data.hexStringEncoded(), chainCode2)
        XCTAssertEqual(key2.toStringRaw(), privateKey2)
        XCTAssert(publicKey2.contains(key2.publicKey.toStringRaw()))

        // Chain m/44'/3030'/0'/0/2147483647; Passphrase "some pass"
        let key3 = try mnemonic.toStandardECDSAsecp256k1PrivateKey("some pass", 2_147_483_647)
        XCTAssertEqual(key3.chainCode!.data.hexStringEncoded(), chainCode3)
        XCTAssertEqual(key3.toStringRaw(), privateKey3)
        XCTAssert(publicKey3.contains(key3.publicKey.toStringRaw()))

        // Chain m/44'/3030'/0'/0/0'
        let key4 = try mnemonic.toStandardECDSAsecp256k1PrivateKey("", Bip32Utils.toHardenedIndex(0))
        XCTAssertEqual(key4.chainCode!.data.hexStringEncoded(), chainCode4)
        XCTAssertEqual(key4.toStringRaw(), privateKey4)
        XCTAssert(publicKey4.contains(key4.publicKey.toStringRaw()))

        // Chain m/44'/3030'/0'/0/2147483647'; Passphrase "some pass"
        let key5 = try mnemonic.toStandardECDSAsecp256k1PrivateKey(
            "some pass", Bip32Utils.toHardenedIndex(2_147_483_647))
        XCTAssertEqual(key5.chainCode!.data.hexStringEncoded(), chainCode5)
        XCTAssertEqual(key5.toStringRaw(), privateKey5)
        XCTAssert(publicKey5.contains(key5.publicKey.toStringRaw()))
    }
}
