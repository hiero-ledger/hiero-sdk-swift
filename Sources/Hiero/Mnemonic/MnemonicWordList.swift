// SPDX-License-Identifier: Apache-2.0

/// Mnemonic word list utilities for BIP-39 and legacy word lookups.
///
/// This file provides `MnemonicWordList`, an efficient data structure for:
/// - Looking up word indices during mnemonic parsing
/// - Retrieving words by index during mnemonic generation
///
/// Supports both sorted (BIP-39) and unsorted (legacy) word lists with
/// optimized lookup algorithms for each case.

extension StringProtocol {
    fileprivate func compare<S: StringProtocol>(to other: S) -> Ordering {
        if self < other {
            return .less
        } else if self > other {
            return .greater
        } else {
            // the two must be equal.
            return .equal
        }
    }
}

internal struct MnemonicWordList: ExpressibleByStringLiteral {
    internal init(stringLiteral value: StringLiteralType) {
        words = value.split { $0.isNewline }
        isSorted = words.isSorted()
    }

    private let words: [Substring]
    private let isSorted: Bool

    internal func indexOf<S: StringProtocol>(word: S) -> Int? {
        switch isSorted {
        case false: return words.firstIndex { $0 == word }
        case true: return words.binarySearch { $0.compare(to: word) }
        }
    }

    internal subscript(index: Int) -> Substring? {
        words[safe: index]
    }
}

extension Array where Element: Comparable {
    fileprivate func isSorted() -> Bool {
        // empty and mono-element arrays are sorted, just,
        // by nature of there being no (other) elements.
        if self.count < 2 {
            return true
        }

        return zip(self[1...], self).allSatisfy { !($0 > $1) }
    }
}
