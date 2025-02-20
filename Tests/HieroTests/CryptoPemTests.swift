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
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class CryptoPemTests: XCTestCase {
    internal func testLabelType() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            MIGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            -----END PRIVATE KEY-----
            """

        let doc = try Crypto.Pem.decode(pemString)

        XCTAssertEqual(doc.typeLabel, "PRIVATE KEY")
    }

    internal func testExceedsLineLimitFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            MIGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAwMIGb
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try Crypto.Pem.decode(pemString))
    }

    internal func testShortLineFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            MIGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFD
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try Crypto.Pem.decode(pemString))
    }

    internal func testNonBase64CharacterFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            ≈MIGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try Crypto.Pem.decode(pemString))
    }

    internal func testBadHeaderFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEYS-----
            MIGbMFcGCSqGSIb3DQEFDSTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try Crypto.Pem.decode(pemString))
    }

    internal func testBadFooterFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            MIGbMFcGCSqGSIb3DQEFDSTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            -----END PRIVATE KEYS-----
            """

        XCTAssertThrowsError(try Crypto.Pem.decode(pemString))
    }

    internal func testBase64CharacterFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            @IGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try Crypto.Pem.decode(pemString))
    }
}
