// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

/// Configuration for test operator account
public struct OperatorConfig {
    public let accountId: AccountId
    public let privateKey: PrivateKey

    public init(accountId: AccountId, privateKey: PrivateKey) {
        self.accountId = accountId
        self.privateKey = privateKey
    }

    /// Load operator configuration from environment variables
    public static func fromEnvironment() throws -> Self? {
        guard let accountIdStr = EnvironmentVariables.operatorId,
            let keyStr = EnvironmentVariables.operatorKey
        else {
            return nil
        }

        let accountId = try AccountId.fromString(accountIdStr)
        let key = try PrivateKey.fromString(keyStr)

        return OperatorConfig(accountId: accountId, privateKey: key)
    }
}
