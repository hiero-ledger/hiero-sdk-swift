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

internal final class TokenInfoTests: XCTestCase {
    private static let adminKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e11"
    private static let kycKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e12"
    private static let freezeKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e13"
    private static let wipeKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e14"
    private static let supplyKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e15"
    private static let feeScheduleKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e16"
    private static let pauseKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e17"
    private static let metadataKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e18"

    private static let tokenInfo: TokenInfo = TokenInfo(
        tokenId: "0.6.9",
        name: "test token name",
        symbol: "TTN",
        decimals: 3,
        totalSupply: 1000,
        treasuryAccountId: "7.7.7",
        adminKey: .single(adminKey.publicKey),
        kycKey: .single(kycKey.publicKey),
        freezeKey: .single(freezeKey.publicKey),
        wipeKey: .single(wipeKey.publicKey),
        supplyKey: .single(supplyKey.publicKey),
        feeScheduleKey: .single(feeScheduleKey.publicKey),
        defaultFreezeStatus: true,
        defaultKycStatus: true,
        isDeleted: false,
        autoRenewAccount: "8.9.0",
        autoRenewPeriod: .hours(10),
        expirationTime: .init(seconds: 1_554_158_542, subSecondNanos: 0),
        tokenMemo: "memo",
        tokenType: .fungibleCommon,
        supplyType: .finite,
        maxSupply: 1_000_000,
        customFees: [
            .fixed(.init(amount: 10, denominatingTokenId: 483902, feeCollectorAccountId: 4322)),
            .fractional(
                .init(
                    amount: "3/7", minimumAmount: 3, maximumAmount: 100, assessmentMethod: .inclusive,
                    feeCollectorAccountId: 4322)),
        ],
        pauseKey: .single(pauseKey.publicKey),
        pauseStatus: true,
        ledgerId: .mainnet,
        metadata: Resources.metadata,
        metadataKey: .single(metadataKey.publicKey)
    )

    internal func testSerialize() throws {
        let info = try TokenInfo.fromBytes(Self.tokenInfo.toBytes())

        assertSnapshot(matching: info, as: .description)
    }

    internal func testFromProtobuf() throws {
        let pb = Self.tokenInfo.toProtobuf()

        let info = try TokenInfo.fromProtobuf(pb)

        assertSnapshot(matching: info, as: .description)
    }

    internal func testToProtobuf() {
        let info = Self.tokenInfo.toProtobuf()
        assertSnapshot(matching: info, as: .description)
    }
}
