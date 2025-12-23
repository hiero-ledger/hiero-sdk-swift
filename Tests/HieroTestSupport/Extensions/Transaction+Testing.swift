// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

@testable import Hiero

/// Testing extensions for Transaction types
///
/// Note: This uses `@testable import Hiero` to access internal `makeSources()` method.
/// This is intentional as this extension is only for test targets.
extension Transaction {
    /// Creates a protobuf transaction body from the transaction for testing purposes.
    ///
    /// This is useful for snapshot testing and comparing transaction serialization.
    ///
    /// - Returns: The protobuf transaction body
    /// - Throws: If serialization fails
    public func makeProtoBody() throws -> Proto_TransactionBody {
        try Proto_TransactionBody(serializedBytes: makeSources().signedTransactions[0].bodyBytes)
    }
}
