// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class CryptoPemUnitTests: HieroUnitTestCase {
    internal func test_LabelType() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            MIGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            -----END PRIVATE KEY-----
            """

        let doc = try Pem.decode(pemString)

        XCTAssertEqual(doc.typeLabel, "PRIVATE KEY")
    }

    internal func test_ExceedsLineLimitFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            MIGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAwMIGb
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try Pem.decode(pemString))
    }

    internal func test_ShortLineFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            MIGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFD
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try Pem.decode(pemString))
    }

    internal func test_NonBase64CharacterFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            ≈MIGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try Pem.decode(pemString))
    }

    internal func test_BadHeaderFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEYS-----
            MIGbMFcGCSqGSIb3DQEFDSTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try Pem.decode(pemString))
    }

    internal func test_BadFooterFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            MIGbMFcGCSqGSIb3DQEFDSTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            -----END PRIVATE KEYS-----
            """

        XCTAssertThrowsError(try Pem.decode(pemString))
    }

    internal func test_Base64CharacterFail() throws {
        let pemString =
            """
            -----BEGIN PRIVATE KEY-----
            @IGbMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAjeB6TNNQX+1gICCAAw
            -----END PRIVATE KEY-----
            """

        XCTAssertThrowsError(try Pem.decode(pemString))
    }
}
