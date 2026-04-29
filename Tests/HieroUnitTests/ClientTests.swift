import XCTest

@testable import Hiero

final class ClientTests: XCTestCase {
    func test_getOperatorPublicKey_returnsPublicKey() throws {
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

    func test_getOperatorPublicKey_returnsNilWhenNoOPeratorSet() throws {
        let client = Client.forTestnet()

        XCTAssertNil(client.getOperatorPublicKey())
    }
}