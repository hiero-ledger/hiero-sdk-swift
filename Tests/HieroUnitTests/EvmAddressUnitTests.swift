// SPDX-License-Identifier: Apache-2.0

import XCTest

@testable import Hiero

internal final class EvmAddressUnitTests: XCTestCase {
    internal func test_FromStringWithPrefix() throws {
        let address = try EvmAddress.fromString("0x1234567890abcdef1234567890abcdef12345678")

        XCTAssertEqual(address.toString(), "0x1234567890abcdef1234567890abcdef12345678")
    }

    internal func test_FromStringWithoutPrefix() throws {
        let address = try EvmAddress.fromString("1234567890abcdef1234567890abcdef12345678")

        XCTAssertEqual(address.toString(), "0x1234567890abcdef1234567890abcdef12345678")
    }

    internal func test_FromStringUppercase() throws {
        let address = try EvmAddress.fromString("0x1234567890ABCDEF1234567890ABCDEF12345678")

        XCTAssertEqual(address.toString(), "0x1234567890abcdef1234567890abcdef12345678")
    }

    internal func test_FromStringInvalidLength() {
        XCTAssertThrowsError(try EvmAddress.fromString("0x1234")) { error in
            guard let error = error as? HError else {
                XCTFail("Expected HError, got \(type(of: error))")
                return
            }

            XCTAssertEqual(error.kind, .basicParse)
            XCTAssertEqual(error.description, "expected evm address to have 20 bytes, it had 2")
        }
    }

    internal func test_FromStringInvalidHex() {
        XCTAssertThrowsError(try EvmAddress.fromString("0xGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG")) { error in
            guard let error = error as? HError else {
                XCTFail("Expected HError, got \(type(of: error))")
                return
            }

            XCTAssertEqual(error.kind, .basicParse)
            XCTAssertEqual(error.description, "invalid evm address")
        }
    }

    internal func test_FromStringEmpty() {
        XCTAssertThrowsError(try EvmAddress.fromString("")) { error in
            guard let error = error as? HError else {
                XCTFail("Expected HError, got \(type(of: error))")
                return
            }

            XCTAssertEqual(error.kind, .basicParse)
            XCTAssertEqual(error.description, "expected evm address to have 20 bytes, it had 0")
        }
    }

    internal func test_ToString() throws {
        let address = try EvmAddress.fromString("0x1234567890ABCDEF1234567890ABCDEF12345678")

        XCTAssertEqual(address.toString(), "0x1234567890abcdef1234567890abcdef12345678")
        XCTAssertEqual(address.description, "0x1234567890abcdef1234567890abcdef12345678")
    }

    internal func test_ToBytes() throws {
        let address = try EvmAddress.fromString("0x0000000000000000000000000000000000000001")
        let bytes = address.toBytes()

        XCTAssertEqual(bytes.count, 20)
        XCTAssertEqual(bytes.last, 0x01)
    }

    internal func test_FromBytes() throws {
        var data = Data(repeating: 0, count: 20)
        data[19] = 0x42

        let address = try EvmAddress.fromBytes(data)

        XCTAssertEqual(address.toString(), "0x0000000000000000000000000000000000000042")
    }

    internal func test_FromBytesInvalidLength() {
        XCTAssertThrowsError(try EvmAddress.fromBytes(Data([0x01, 0x02, 0x03]))) { error in
            guard let error = error as? HError else {
                XCTFail("Expected HError, got \(type(of: error))")
                return
            }

            XCTAssertEqual(error.kind, .basicParse)
            XCTAssertEqual(error.description, "expected evm address to have 20 bytes, it had 3")
        }
    }

    internal func test_Equatable() throws {
        let a = try EvmAddress.fromString("0x1234567890abcdef1234567890abcdef12345678")
        let b = try EvmAddress.fromString("0x1234567890abcdef1234567890abcdef12345678")
        let c = try EvmAddress.fromString("0x0000000000000000000000000000000000000001")

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    internal func test_Hashable() throws {
        let a = try EvmAddress.fromString("0x1234567890abcdef1234567890abcdef12345678")
        let b = try EvmAddress.fromString("0x1234567890abcdef1234567890abcdef12345678")
        let c = try EvmAddress.fromString("0x0000000000000000000000000000000000000001")
        let addresses: Set<EvmAddress> = [a, b, c]

        XCTAssertEqual(addresses.count, 2)
        XCTAssertTrue(addresses.contains(a))
        XCTAssertTrue(addresses.contains(c))
    }

    internal func test_LosslessStringConvertible() {
        let parse: (String) -> EvmAddress? = EvmAddress.init
        let address = parse("0x1234567890abcdef1234567890abcdef12345678")
        let invalidAddress = parse("0x1234")

        XCTAssertEqual(address?.toString(), "0x1234567890abcdef1234567890abcdef12345678")
        XCTAssertNil(invalidAddress)
    }

    internal func test_StringLiteral() {
        let address: EvmAddress = "0x1234567890abcdef1234567890abcdef12345678"

        XCTAssertEqual(address.toString(), "0x1234567890abcdef1234567890abcdef12345678")
    }
}
