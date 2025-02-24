import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class AccountBalanceQueryTests: XCTestCase {
    internal func testSerializeWithAccountId() {
        let proto = AccountBalanceQuery(accountId: 5005).toQueryProtobufWith(Proto_QueryHeader())
        assertSnapshot(matching: proto, as: .description)
    }

    internal func testSerializeWithContractId() {
        let proto = AccountBalanceQuery(contractId: 5005).toQueryProtobufWith(Proto_QueryHeader())
        assertSnapshot(matching: proto, as: .description)
    }

    internal func testGetSetAccountId() {
        let query = AccountBalanceQuery()
        query.accountId(5005)

        XCTAssertEqual(query.accountId, 5005)
    }

    internal func testGetSetContractId() {
        let query = AccountBalanceQuery()
        query.contractId(1414)

        XCTAssertEqual(query.contractId, 1414)
    }
}
