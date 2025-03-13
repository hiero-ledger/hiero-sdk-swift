// SPDX-License-Identifier: Apache-2.0

extension StringProtocol {
    fileprivate func splitAt(index: Index) -> (SubSequence, SubSequence) {
        (self[..<index], self[self.index(after: index)...])
    }

    internal func splitOnce(on separator: Element) -> (SubSequence, SubSequence)? {
        firstIndex(of: separator).map { index in
            self.splitAt(index: index)
        }
    }

    internal func rsplitOnce(on separator: Element) -> (SubSequence, SubSequence)? {
        lastIndex(of: separator).map { index in
            self.splitAt(index: index)
        }
    }

    internal func stripPrefix<S: StringProtocol>(_ prefix: S) -> SubSequence? {
        if self.starts(with: prefix) {
            return self[self.index(self.startIndex, offsetBy: prefix.count)...]
        }

        return nil
    }

    internal func stripSuffix<S: StringProtocol>(_ suffix: S) -> SubSequence? {
        if self.hasSuffix(suffix) {
            return self[..<self.index(self.endIndex, offsetBy: -suffix.count)]
        }

        return nil
    }
}
