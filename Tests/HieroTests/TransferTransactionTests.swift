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

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TransferTransactionTests: XCTestCase {
    private static func makeTransaction() throws -> TransferTransaction {
        // CI thinks this is too big of an expression, so, it's split into a few parts
        let tx = TransferTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)

        tx.hbarTransfer(AccountId(num: 5008), Hbar.fromTinybars(400))
            .hbarTransfer(AccountId(num: 5006), Hbar.fromTinybars(800).negated())
            .approvedHbarTransfer(AccountId(num: 5007), Hbar.fromTinybars(400))

        tx.tokenTransfer(TokenId(num: 5), AccountId(num: 5008), 400)
            .tokenTransferWithDecimals(TokenId(num: 5), AccountId(num: 5006), -800, 3)
            .tokenTransferWithDecimals(TokenId(num: 5), AccountId(num: 5007), 400, 3)
            .tokenTransfer(TokenId(num: 4), AccountId(num: 5008), 1)
            .approvedTokenTransfer(TokenId(num: 4), AccountId(num: 5006), -1)

        tx.nftTransfer(TokenId(num: 3).nft(2), AccountId(num: 5008), AccountId(num: 5007))
            .approvedNftTransfer(TokenId(num: 3).nft(1), AccountId(num: 5008), AccountId(num: 5007))
            .nftTransfer(TokenId(num: 3).nft(3), AccountId(num: 5008), AccountId(num: 5006))
            .nftTransfer(TokenId(num: 3).nft(4), AccountId(num: 5007), AccountId(num: 5006))
            .nftTransfer(TokenId(num: 2).nft(4), AccountId(num: 5007), AccountId(num: 5006))

        return try tx.freeze()
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testGetDecimals() {
        let tx = TransferTransaction()
        let token = TokenId(num: 5)

        XCTAssertNil(tx.tokenDecimals[token])

        tx.tokenTransfer(token, 8, 100)
        XCTAssertNil(tx.tokenDecimals[token])

        tx.tokenTransferWithDecimals(token, 7, -100, 5)
        XCTAssertEqual(tx.tokenDecimals[token], 5)
    }
}
