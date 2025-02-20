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

import SnapshotTesting
import XCTest

import struct HieroProtobufs.Proto_Key

@testable import Hiero

internal final class LedgerIdTests: XCTestCase {
    internal func testToString() throws {
        XCTAssertEqual(LedgerId.mainnet.toString(), "mainnet")
        XCTAssertEqual(LedgerId.testnet.toString(), "testnet")
        XCTAssertEqual(LedgerId.previewnet.toString(), "previewnet")
        XCTAssertEqual(LedgerId.fromBytes(Data([0x00, 0xFF, 0x00, 0xFF])), "00FF00FF")
    }

    internal func testFromString() throws {
        XCTAssertEqual(LedgerId.fromString("mainnet"), LedgerId.mainnet)
        XCTAssertEqual(LedgerId.fromString("testnet"), LedgerId.testnet)
        XCTAssertEqual(LedgerId.fromString("previewnet"), LedgerId.previewnet)
        XCTAssertEqual(LedgerId.fromString("00ff00ff"), LedgerId.fromBytes(Data([0x00, 0xFF, 0x00, 0xFF])))
        XCTAssertEqual(LedgerId.fromString("00FF00FF"), LedgerId.fromBytes(Data([0x00, 0xFF, 0x00, 0xFF])))
    }

    internal func testToBytes() throws {
        let bytes = Data([0x00, 0xFF, 0x00, 0xFF])
        XCTAssertEqual(LedgerId.fromBytes(Data([0x00, 0xFF, 0x00, 0xFF])).bytes, bytes)
    }
}
