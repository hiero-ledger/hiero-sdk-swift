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

import Foundation

public struct Checksum: Sendable, LosslessStringConvertible, Hashable {
    internal let data: String

    public init?<S: StringProtocol>(_ description: S) {
        guard description.allSatisfy({ $0.isASCII && $0.isLowercase && $0.isLetter }), description.count == 5 else {
            return nil
        }

        self.data = String(description)
    }

    internal init<S: StringProtocol>(parsing description: S) throws {
        guard let tmp = Self(description) else {
            throw HError.basicParse("Invalid checksum string \(description)")
        }

        self = tmp
    }

    internal init?(data: Data) {
        guard data.count == 5 else {
            return nil
        }

        let str = String(data: data, encoding: .ascii)!
        // fixme: check for ascii-alphanumeric

        self.data = str
    }

    // swift doesn't have any other way to do "fixed length array"
    // swiftlint:disable:next large_tuple
    internal init(bytes: (UInt8, UInt8, UInt8, UInt8, UInt8)) {
        // swiftlint:disable:next identifier_name
        let (a, b, c, d, e) = bytes
        // fixme: check for ascii-alphanumeric
        self.data = String(data: Data([a, b, c, d, e]), encoding: .ascii)!
    }

    public var description: String {
        data
    }

    /// The base used for the checksum (ascii a-z is base 26)
    private static let base = 26
    /// 3 digits in `base`
    private static let digits3 = base.toPower(of: 3)
    /// 5 digits in `base`
    private static let digits5 = base.toPower(of: 5)
    //. Sum s of digit values weights them by powers of W. Should be coprime to ``digits5``.
    private static let weight = 31
    /// ``weight`` to the 6th power.
    private static let weight6 = weight.toPower(of: 6)

    /// Computes the hash of a given ledger ID (sh).
    ///
    /// >Note: This is always the same for a given ledger ID.
    private static func ledgerIdHash(ledgerId: LedgerId) -> Int {
        // we can specialize for known ledger IDs since they're, well, known, but it isn't actually clear if that'd be better codegen, thanks swift.

        // instead of six 0 bytes, we compute this in two steps
        var sh = ledgerId.bytes.reduce(0) { (result, value) in (weight * result + Int(value)) % digits5 }
        // `(w * result + Int(0)) % p5` applied 6 times...
        // `(w * result + Int(0)) % p5 = (w * result) % p5` because 0 is the additive identity
        // then expanding out the full expression:
        // `((w * ((w * ((w * ((w * ((w * ((w * result) % p5)) % p5)) % p5)) % p5)) % p5)) % p5)`
        // ... and using the fact that `((x % y) * z) % y = (x * z) % y`
        // we get:
        sh = (sh * weight6) % digits5

        return sh
    }

    internal static func generate<E: EntityId>(for entity: E, on ledgerId: LedgerId) -> Self {
        // min prime greater than a million. Used for the final permutation.
        let minPrime = 1_000_003

        let digits = entity.description.map { $0 == "." ? 10 : $0.wholeNumberValue! }

        // Weighted sum of all positions (mod P3)
        var sum = 0
        // Sum of even positions (mod 11)
        var evenSum = 0
        // Sum of odd positions (mod 11)
        var oddSum = 0

        for (index, digit) in digits.enumerated() {
            sum = (weight * sum + digit) % digits3
            if index.isOdd {
                oddSum += digit
            } else {
                evenSum += digit
            }
        }

        evenSum = evenSum % 11
        oddSum = oddSum % 11

        // original expression:
        // var c = ((((((entityIdString.count % 5) * 11 + s0) * 11 + s1) * p3 + s + sh) % p5) * m) % p5
        // but `((x % y) * z) % y = ((x * z) % y) % y = (x * z) % y`
        // checksum as a single number
        // computation is split into two parts because it's a big expression.
        var c = ((digits.count % 5) * 11 + evenSum) * 11 + oddSum
        c = ((c * digits3 + sum + ledgerIdHash(ledgerId: ledgerId)) * minPrime) % digits5

        var output: [UInt8] = [0, 0, 0, 0, 0]

        for i in (0..<5).reversed() {
            let asciiLowercaseA = 0x61
            let res = c.quotientAndRemainder(dividingBy: base)
            output[i] = UInt8(asciiLowercaseA + res.remainder)
            c = res.quotient
        }

        // thanks swift, for not having fixed length arrays
        return Checksum(bytes: (output[0], output[1], output[2], output[3], output[4]))
    }
}
