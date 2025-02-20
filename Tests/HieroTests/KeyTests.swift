/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
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

import HieroProtobufs
import XCTest

@testable import Hiero

internal final class KeyTests: XCTestCase {
    internal func testFromProtoKeyEd25519() throws {
        let keyBytes = Data(hexEncoded: "0011223344556677889900112233445566778899001122334455667788990011")!

        let keyProto = Proto_Key.with { proto in
            proto.key = .ed25519(keyBytes)
        }

        let key = try PublicKey.fromProtobuf(keyProto)

        XCTAssert(key.isEd25519())
        XCTAssertEqual(key.toBytesRaw(), keyBytes)
    }

    internal func testFromProtoKeyEcdsa() throws {
        let keyBytes = Data(hexEncoded: "3a21034e0441201f2bf9c7d9873c2a9dc3fd451f64b7c05e17e4d781d916e3a11dfd99")!

        let keyProto = try Proto_Key.init(serializedBytes: keyBytes)

        let key = try PublicKey.fromProtobuf(keyProto)

        XCTAssert(key.isEcdsa())
        XCTAssertEqual(Key.single(key).toBytes(), keyBytes)
    }

    internal func testFromProtoKeyKeyList() throws {
        let keyBytes1 = Data(hexEncoded: "0011223344556677889900112233445566778899001122334455667788990011")!
        let keyBytes2 = Data(hexEncoded: "aa11223344556677889900112233445566778899001122334455667788990011")!

        let keyProto1 = Proto_Key.with { proto in
            proto.key = .ed25519(keyBytes1)
        }

        let keyProto2 = Proto_Key.with { proto in
            proto.key = .ed25519(keyBytes2)
        }

        let keysArray = [keyProto1, keyProto2]

        let keyProto = Proto_Key.with { proto in
            proto.keyList = .with { proto in
                proto.keys = keysArray
            }
        }

        let keys = try Key.fromProtobuf(keyProto)

        var keyList: KeyList = KeyList.init()

        switch keys {
        case .keyList(let key):
            keyList = key
        default:
            fatalError("Expected keylist")
        }

        XCTAssertEqual(keyList.count, keysArray.count)

        let actual = keyList.toProtobuf()

        XCTAssertEqual(actual.keys[0].ed25519.bytes, keyBytes1.bytes)
        XCTAssertEqual(actual.keys[1].ed25519.bytes, keyBytes2.bytes)
    }

    internal func testFromProtoKeyThresholdKey() throws {
        let keyBytes1 = Data(hexEncoded: "0011223344556677889900112233445566778899001122334455667788990011")!
        let keyBytes2 = Data(hexEncoded: "aa11223344556677889900112233445566778899001122334455667788990011")!

        let keyProto1 = Proto_Key.with { proto in
            proto.key = .ed25519(keyBytes1)
        }

        let keyProto2 = Proto_Key.with { proto in
            proto.key = .ed25519(keyBytes2)
        }

        let keysArray = [keyProto1, keyProto2]

        let keyListProto = Proto_KeyList.with { proto in
            proto.keys = keysArray
        }

        let thresholdKeyProto = Proto_ThresholdKey.with { proto in
            proto.threshold = 1
            proto.keys = keyListProto
        }

        let keyProto = Proto_Key.with { proto in
            proto.thresholdKey = thresholdKeyProto
        }

        let key = try Key.fromProtobuf(keyProto)

        var keyList = KeyList.init()
        // var thresholdKeyProto2 = Proto_ThresholdKey.init()

        switch key {
        case .keyList(let key):
            keyList = key
        default:
            fatalError("Expected keylist")
        }

        XCTAssertEqual(keyList.count, keysArray.count)

        let thresholdKey = key
        let actual = thresholdKey.toProtobuf().thresholdKey

        XCTAssertEqual(actual.threshold, 1)
        XCTAssertEqual(actual.keys.keys[0].ed25519.bytes, keyBytes1.bytes)
        XCTAssertEqual(actual.keys.keys[1].ed25519.bytes, keyBytes2.bytes)
    }

    internal func testUnsupportedKeyFails() throws {
        let key = Proto_Key.with { proto in
            proto.key = .rsa3072(Data([0, 1, 2]))
        }
        XCTAssertThrowsError(try Key.fromProtobuf(key))
    }
}
