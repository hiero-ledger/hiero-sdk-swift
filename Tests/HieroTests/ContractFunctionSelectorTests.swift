// SPDX-License-Identifier: Apache-2.0

import XCTest

@testable import Hiero

internal final class ContractFunctionSelectorTests: XCTestCase {
    internal func testMiscParams() {
        let result = ContractFunctionSelector("foo")
            .addUint8()
            .addInt8()
            .addUint32()
            .addInt32()
            .addUint64()
            .addInt64()
            .addUint256()
            .addInt256()
            .addUint8Array()
            .addInt8Array()
            .addUint32Array()
            .addInt32Array()
            .addUint64Array()
            .addInt64Array()
            .addUint256Array()
            .addInt256Array()
            .finish()

        XCTAssertEqual(result.hexStringEncoded(), "11bcd903")
    }

    internal func testAddress() {
        let result = ContractFunctionSelector("foo").addAddress().addAddress().addAddressArray().finish()

        XCTAssertEqual(result.hexStringEncoded(), "7d48c86d")
    }

    internal func testFunction() {
        let result = ContractFunctionSelector("foo").addFunction().addFunction().finish()

        XCTAssertEqual(result.hexStringEncoded(), "c99c40cd")
    }

    internal func testSelectorAllTypes() {
        let signature = ContractFunctionSelector("testFunction")
            .addAddress()
            .addAddressArray()
            .addBool()
            .addBytes()
            .addBytes32()
            .addBytes32Array()
            .addBytesArray()
            .addFunction()
            .addInt8()
            .addInt8Array()
            .addInt32()
            .addInt32Array()
            .addInt64()
            .addInt64Array()
            .addInt256()
            .addInt256Array()
            .addUint8()
            .addUint8Array()
            .addUint32()
            .addUint32Array()
            .addUint64()
            .addUint64Array()
            .addUint256()
            .addUint256Array()
            .addString()
            .addStringArray()
            .finish()

        XCTAssertEqual(signature.hexStringEncoded(), "4438e4ce")
    }
}
