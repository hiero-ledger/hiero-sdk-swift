// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import SwiftDotenv

/// Environment configuration for Hiero examples
public struct Environment {
    /// The name of the Hedera network to connect to
    public let networkName: String

    /// The account ID of the operator
    public let operatorAccountId: AccountId

    /// The private key of the operator
    public let operatorKey: PrivateKey

    /// The file ID of the exchange rates
    public let exchangeRatesFile: FileId

    /// Loads environment variables from .env file
    /// - Returns: Environment configuration
    /// - Throws: Error if required environment variables are missing
    public static func load() throws -> Environment {
        try Dotenv.configure()
        let networkName: String = Dotenv.processInfo.environment["HEDERA_NETWORK"] ?? "testnet"
        let operatorAccountId = AccountId(Dotenv.processInfo.environment["OPERATOR_ID"]!)!
        let operatorKey = PrivateKey(Dotenv.processInfo.environment["OPERATOR_KEY"]!)!
        let exchangeRatesFile = FileId(Dotenv.processInfo.environment["HEDERA_EXCHANGE_RATES_FILE"] ?? "0.0.1000")!
        return Environment(
            networkName: networkName, operatorAccountId: operatorAccountId, operatorKey: operatorKey,
            exchangeRatesFile: exchangeRatesFile)
    }
}
