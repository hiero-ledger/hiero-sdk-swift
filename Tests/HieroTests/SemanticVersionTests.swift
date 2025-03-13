// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class SemanticVersionTests: XCTestCase {
    internal func testParseMajorMinorPatch() throws {
        let semver = try XCTUnwrap(SemanticVersion("1.2.3"))

        XCTAssertEqual(semver.major, 1)
        XCTAssertEqual(semver.minor, 2)
        XCTAssertEqual(semver.patch, 3)
        XCTAssertEqual(semver.prerelease, "")
        XCTAssertEqual(semver.build, "")
    }

    internal func testParseZeroMinorPatch() throws {
        let semver = try XCTUnwrap(SemanticVersion("0.2.0"))

        XCTAssertEqual(semver.major, 0)
        XCTAssertEqual(semver.minor, 2)
        XCTAssertEqual(semver.patch, 0)
        XCTAssertEqual(semver.prerelease, "")
        XCTAssertEqual(semver.build, "")
    }

    internal func testParseWithPrerelease() throws {
        let semver = try XCTUnwrap(SemanticVersion("1.2.0-beta.10"))

        XCTAssertEqual(semver.major, 1)
        XCTAssertEqual(semver.minor, 2)
        XCTAssertEqual(semver.patch, 0)
        XCTAssertEqual(semver.prerelease, "beta.10")
        XCTAssertEqual(semver.build, "")
    }

    internal func testParseWithBuild() throws {
        let semver = try XCTUnwrap(SemanticVersion("1.2.0+d13fe780"))

        XCTAssertEqual(semver.major, 1)
        XCTAssertEqual(semver.minor, 2)
        XCTAssertEqual(semver.patch, 0)
        XCTAssertEqual(semver.prerelease, "")
        XCTAssertEqual(semver.build, "d13fe780")
    }

    internal func testParseWithPrereleaseAndBuild() throws {
        let semver = try XCTUnwrap(SemanticVersion("1.2.0-beta.10+d13fe780"))

        XCTAssertEqual(semver.major, 1)
        XCTAssertEqual(semver.minor, 2)
        XCTAssertEqual(semver.patch, 0)
        XCTAssertEqual(semver.prerelease, "beta.10")
        XCTAssertEqual(semver.build, "d13fe780")
    }

    internal func testBasic() {
        XCTAssertEqual(SemanticVersion(major: 1, minor: 2, patch: 3).description, "1.2.3")
    }

    internal func testWithPrerelease() {
        XCTAssertEqual(SemanticVersion(major: 3, minor: 1, patch: 4, prerelease: "15.92").description, "3.1.4-15.92")
    }

    internal func testWithBuild() {
        XCTAssertEqual(SemanticVersion(major: 1, minor: 41, patch: 1, build: "6535asd").description, "1.41.1+6535asd")
    }

    internal func testWithPrereleaseAndBuild() {
        XCTAssertEqual(
            SemanticVersion(major: 0, minor: 1, patch: 4, prerelease: "0.9a2", build: "sha.25531c").description,
            "0.1.4-0.9a2+sha.25531c"
        )
    }

    internal func testToProtobuf() {
        assertSnapshot(matching: SemanticVersion("1.2.0-beta.10+d13fe780").toProtobuf(), as: .description)
    }

    internal func testFromProtobuf() {
        let semver = SemanticVersion.fromProtobuf(
            .with { proto in
                proto.major = 1
                proto.minor = 2
                proto.patch = 0
                proto.pre = "beta.10"
                proto.build = "d13fe780"
            }
        )

        assertSnapshot(matching: semver, as: .description)
    }
}
