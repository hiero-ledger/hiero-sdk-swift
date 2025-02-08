// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

import struct HieroProtobufs.Proto_Key

@testable import Hiero

internal final class KeyListTests: XCTestCase {
    private static let testPrivateKey1 = Resources.privateKey
    private static let testPrivateKey2: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e11"
    private static let testPrivateKey3: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e12"

    private func keys() -> [Key] {
        let key1 = Key.single(Self.testPrivateKey1.publicKey)
        let key2 = Key.single(Self.testPrivateKey2.publicKey)
        let key3 = Key.single(Self.testPrivateKey3.publicKey)

        return [key1, key2, key3]
    }

    internal func testFromProtobuf() throws {
        let keys = keys()
        let protoKeyList = KeyList.init(keys: keys, threshold: 3).toProtobuf()

        let keyList = try KeyList.fromProtobuf(protoKeyList)

        XCTAssertTrue(keyList.contains(keys[0]))
        XCTAssertTrue(keyList.contains(keys[1]))
        XCTAssertTrue(keyList.contains(keys[2]))
    }

    internal func testKeys() {
        let keys = keys()

        let keyList = KeyList.init(keys: keys)

        XCTAssertTrue(keyList.contains(keys[0]))
        XCTAssertTrue(keyList.contains(keys[1]))
        XCTAssertTrue(keyList.contains(keys[2]))
    }

    internal func testToProtobufKey() {
        let keyList = KeyList.init(keys: keys())

        let protoKey = keyList.toProtobufKey()

        XCTAssertEqual(protoKey, Proto_Key.OneOf_Key.keyList(keyList.toProtobuf()))
    }

    internal func testToProtobuf() {
        let keys = keys()
        let keyList = KeyList.init(keys: keys)

        let protoKeyList = keyList.toProtobuf()

        XCTAssertEqual(protoKeyList.keys.count, 3)
        XCTAssertEqual(protoKeyList.keys[0], keys[0].toProtobuf())
        XCTAssertEqual(protoKeyList.keys[1], keys[1].toProtobuf())
        XCTAssertEqual(protoKeyList.keys[2], keys[2].toProtobuf())
    }

    internal func testLen() {
        let keyList = KeyList.init(keys: keys())
        let emptyKeyList = KeyList()

        XCTAssertEqual(keyList.count, 3)
        XCTAssert(!keyList.isEmpty)
        XCTAssertEqual(emptyKeyList.count, 0)
        XCTAssert(emptyKeyList.isEmpty)
    }

    internal func testContains() {
        let keys = keys()
        let keyList = KeyList.init(keys: keys)
        let emptyKeyList = KeyList()

        for (_, key) in keys.enumerated() {
            XCTAssert(keyList.contains(key))
        }

        for (_, key) in keys.enumerated() {
            XCTAssert(!emptyKeyList.contains(key))
        }
    }

    internal func testAppend() {
        let keys = keys()
        var keyList = KeyList.init(keys: [keys[0], keys[1]])

        keyList.keys.append(keys[2])

        XCTAssertEqual(keyList.count, 3)
        XCTAssert(keyList.contains(keys[2]))
    }

    internal func testRemove() {
        let keys = keys()
        var keyList = KeyList.init(keys: keys)

        _ = keyList.keys.remove(at: 0)

        XCTAssertEqual(keyList.count, 2)

        XCTAssert(!keyList.contains(keys[0]))
        XCTAssert(keyList.contains(keys[1]))
        XCTAssert(keyList.contains(keys[2]))
    }

    internal func testClear() {
        var keyList = KeyList.init(keys: keys())

        keyList.keys.removeAll()

        XCTAssert(keyList.isEmpty)
    }
}
