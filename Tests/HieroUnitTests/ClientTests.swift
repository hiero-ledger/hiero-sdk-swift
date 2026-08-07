import XCTest

@testable import Hiero

internal final class ClientTests: XCTestCase {
    internal func test_getOperatorPublicKey_returnsPublicKey() throws {
        let privateKey = try PrivateKey.fromString(
            "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e10"
        )
        let accountId = try AccountId.fromString("0.0.1001")
        let client = Client.forTestnet()

        client.setOperator(accountId, privateKey)

        let publicKey = client.getOperatorPublicKey()

        XCTAssertNotNil(publicKey)
        XCTAssertEqual(publicKey, privateKey.publicKey)
    }

    internal func test_getOperatorPublicKey_returnsNilWhenNoOperatorSet() throws {
        let client = Client.forTestnet()

        XCTAssertNil(client.getOperatorPublicKey())
    }
}

extension ClientTests {
    func testDefaultMaxQueryPaymentDefaultsToOneHbar() throws {
        let client = Client.forTestnet()
        XCTAssertEqual(client.getDefaultMaxQueryPayment(), Hbar.fromTinybars(100_000_000))
    }

    func testSetDefaultMaxQueryPayment() throws {
        let client = Client.forTestnet()
        try client.setDefaultMaxQueryPayment(Hbar(2))
        XCTAssertEqual(client.getDefaultMaxQueryPayment(), Hbar(2))
    }

    func testNegativeMaxQueryPaymentThrows() throws {
        let client = Client.forTestnet()
        XCTAssertThrowsError(try client.setDefaultMaxQueryPayment(Hbar.fromTinybars(-1)))
    }
}
