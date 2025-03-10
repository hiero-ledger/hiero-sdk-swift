// SPDX-License-Identifier: Apache-2.0

import Foundation

internal protocol ValidateChecksums {
    func validateChecksums(on ledgerId: LedgerId) throws

    func validateChecksums(on client: Client) throws
}

extension ValidateChecksums {
    internal func validateChecksums(on client: Client) throws {
        try validateChecksums(on: client.ledgerId!)
    }
}

extension Array: ValidateChecksums where Self.Element: ValidateChecksums {
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try forEach { element in try element.validateChecksums(on: ledgerId) }
    }
}
