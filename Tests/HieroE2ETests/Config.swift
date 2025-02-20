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

import Hiero
import SwiftDotenv
import XCTest

private struct Bucket {
    /// Divide the entire ratelimit for everything by this amount because we don't actually want to use the entire network's worth of rss.
    private static let globalDivider: Int = 2
    /// Multiply the refresh delay
    private static let refreshMultiplier: Double = 1.05

    /// Create a bucket for at most `limit` items per `refreshDelay`.
    internal init(limit: Int, refreshDelay: TimeInterval) {
        precondition(limit > 0)
        self.limit = max(limit / Self.globalDivider, 1)
        self.refreshDelay = refreshDelay * Self.refreshMultiplier
        self.items = []
    }

    fileprivate var limit: Int
    // how quickly items are removed (an item older than `refreshDelay` is dropped)
    fileprivate var refreshDelay: TimeInterval
    fileprivate var items: [Date]

    fileprivate mutating func next(now: Date = Date()) -> UInt64? {
        items.removeAll { now.timeIntervalSince($0) >= refreshDelay }

        let usedTime: Date

        if items.count >= limit {
            // if the limit is `2` items per `0.5` seconds and we have `3` items, we want `items[1] + 0.5 seconds`
            // because `items[1]` will expire 0.5 seconds after *it* was added.
            usedTime = items[items.count - limit] + refreshDelay
        } else {
            usedTime = now
        }

        items.append(usedTime)

        if usedTime > now {
            return UInt64(usedTime.timeIntervalSince(now) * 1e9)
        }

        return nil
    }
}

/// Ratelimits for the really stringent operations.
///
/// This is a best-effort attempt to protect against E2E tests being flakey due to Hedera having a global ratelimit per transaction type.
internal actor Ratelimit {
    // todo: use something fancier or find something fancier, preferably the latter, but the swift ecosystem is as it is.
    private var accountCreate = Bucket(limit: 2, refreshDelay: 1.0)
    private var file = Bucket(limit: 10, refreshDelay: 1.0)
    // private var topicCreate = Bucket(limit: 5, refreshDelay: 1.0)

    internal func accountCreate() async throws {
        // if let sleepTime = accountCreate.next() {
        //    try await Task.sleep(nanoseconds: sleepTime)
        // }
    }

    internal func file() async throws {
        if let sleepTime = file.next() {
            try await Task.sleep(nanoseconds: sleepTime)
        }
    }
}

internal struct TestEnvironment {
    private let defaultLocalNodeAddress: String = "127.0.0.1:50211"
    private let defaultLocalMirrorNodeAddress: String = "127.0.0.1:5600"
    internal struct Config {
        private static func envBool(env: Environment?, key: String, defaultValue: Bool) -> Bool {
            guard let value = env?[key]?.stringValue else {
                return defaultValue
            }

            switch value {
            case "1":
                return true
            case "0":
                return false
            case _:
                print(
                    "warn: expected `\(key)` to be `1` or `0` but it was `\(value)`, returning `\(defaultValue)`",
                    stderr
                )

                return defaultValue
            }
        }

        fileprivate init() {
            let env = try? Dotenv.load()

            network = env?[Keys.network]?.stringValue ?? "testnet"

            let runNonfree = Self.envBool(env: env, key: Keys.runNonfree, defaultValue: false)

            `operator` = .init(env: env)

            if `operator` == nil && runNonfree {
                print("warn: forcing `runNonfree` to false because operator is nil", stderr)
                self.runNonfreeTests = false
            } else {
                self.runNonfreeTests = runNonfree
            }
        }

        internal let network: String
        internal let `operator`: TestEnvironment.Operator?
        internal let runNonfreeTests: Bool
    }

    internal struct Operator {
        internal init?(env: Environment?) {
            guard let env = env else {
                return nil
            }

            let operatorKeyStr = env[Keys.operatorKey]?.stringValue
            let operatorAccountIdStr = env[Keys.operatorAccountId]?.stringValue

            switch (operatorKeyStr, operatorAccountIdStr) {
            case (nil, nil):
                return nil

            case (.some, nil), (nil, .some):

                // warn:
                return nil

            case (.some(let key), .some(let accountId)):

                do {
                    let accountId = try AccountId.fromString(accountId)
                    let key = try PrivateKey.fromString(key)

                    self.accountId = accountId
                    self.privateKey = key
                } catch {
                    print("warn: forcing operator to nil because an error occurred: \(error)")
                    return nil
                }
            }
        }

        internal let accountId: AccountId
        internal let privateKey: PrivateKey
    }

    private enum Keys {
        fileprivate static let network = "TEST_NETWORK_NAME"
        fileprivate static let operatorKey = "TEST_OPERATOR_KEY"
        fileprivate static let operatorAccountId = "TEST_OPERATOR_ID"
        fileprivate static let runNonfree = "TEST_RUN_NONFREE"
    }

    private init() {
        config = .init()
        ratelimits = .init()

        do {
            switch config.network {
            case "mainnet":
                self.client = Client.forMainnet()
            case "testnet":
                self.client = .forTestnet()
            case "previewnet":
                self.client = Client.forPreviewnet()
            case "localhost":
                var network: [String: AccountId] = [String: AccountId]()

                network[defaultLocalNodeAddress] = AccountId(num: 3)

                let client = try Client.forNetwork(network)

                self.client = client.setMirrorNetwork([defaultLocalMirrorNodeAddress])
            default:
                self.client = Client.forTestnet()
            }
        } catch {
            print("Error creating client: \(config.network); creating one using testnet")

            self.client = Client.forTestnet()
        }

        if let op = config.operator {
            self.client.setOperator(op.accountId, op.privateKey)
        }
    }

    internal static let global: TestEnvironment = TestEnvironment()
    internal static var nonFree: NonfreeTestEnvironment {
        get throws {
            if let inner = NonfreeTestEnvironment.global {
                return inner
            }

            throw XCTSkip("Test requires non-free test environment, but the test environment only allows free tests")
        }
    }

    internal let client: Hiero.Client
    internal let config: Config
    internal let ratelimits: Ratelimit

    internal var `operator`: Operator? {
        config.operator
    }
}

internal struct NonfreeTestEnvironment {
    internal struct Config {
        fileprivate init?(base: TestEnvironment.Config) {
            guard base.runNonfreeTests else {
                return nil
            }

            self.operator = base.`operator`!
            self.network = base.network
        }

        internal let network: String
        internal let `operator`: TestEnvironment.Operator
    }

    private init?(_ env: TestEnvironment) {
        guard let config = Config(base: env.config) else {
            return nil
        }

        self.config = config
        self.client = env.client
        self.ratelimits = env.ratelimits
    }

    fileprivate static let global: Self? = Self(.global)

    internal let client: Hiero.Client
    internal let config: Config
    internal let ratelimits: Ratelimit

    internal var `operator`: TestEnvironment.Operator {
        config.operator
    }
}
