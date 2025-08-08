// SPDX-License-Identifier: Apache-2.0

import Hiero
import SwiftDotenv
import XCTest

/// A simple bucket-based ratelimiter to prevent overloading the network during tests.
private struct Bucket {
    /// Divide the entire ratelimit for everything by this amount to avoid using the full network capacity.
    private static let globalDivider: Int = 2
    /// Multiply the refresh delay for safety margin.
    private static let refreshMultiplier: Double = 1.05

    /// Create a bucket for at most `limit` items per `refreshDelay`.
    internal init(limit: Int, refreshDelay: TimeInterval) {
        self.limit = max(limit / Self.globalDivider, 1)
        self.refreshDelay = refreshDelay * Self.refreshMultiplier
        self.items = []
    }

    fileprivate var limit: Int
    // How quickly items are removed (an item older than `refreshDelay` is dropped).
    fileprivate var refreshDelay: TimeInterval
    fileprivate var items: [Date]

    fileprivate mutating func next(now: Date = Date()) -> TimeInterval? {
        items.removeAll { now.timeIntervalSince($0) >= refreshDelay }

        guard items.count >= limit else {
            items.append(now)
            return nil
        }

        // Calculate the time when the next slot opens.
        let usedTime = items[items.count - limit] + refreshDelay

        items.append(usedTime)

        return max(0, usedTime.timeIntervalSince(now))
    }
}

/// Ratelimits for stringent operations to avoid flakiness in E2E tests due to global limits.
internal actor Ratelimit {
    private var accountCreate = Bucket(limit: 2, refreshDelay: 1.0)
    private var file = Bucket(limit: 10, refreshDelay: 1.0)
    // Add more buckets as needed, e.g., private var topicCreate = Bucket(limit: 5, refreshDelay: 1.0)

    internal func accountCreate() async throws {
        if let sleepTime = accountCreate.next() {
            try await Task.sleep(nanoseconds: UInt64(sleepTime * 1e9))
        }
    }

    internal func file() async throws {
        if let sleepTime = file.next() {
            try await Task.sleep(nanoseconds: UInt64(sleepTime * 1e9))
        }
    }
}

/// Shared test environment configuration and utilities.
internal struct TestEnvironment {
    private let defaultLocalNodeAddress: String = "127.0.0.1:50211"
    private let defaultLocalMirrorNodeAddress: String = "127.0.0.1:5600"

    internal struct Config {
        private static func parseBool(from value: String?, defaultValue: Bool) -> Bool {
            guard let value = value else { return defaultValue }
            switch value.lowercased() {
            case "1", "true", "yes": return true
            case "0", "false", "no": return false
            default:
                print("Warning: Invalid boolean value '\(value)' for key; using default \(defaultValue)")
                return defaultValue
            }
        }

        fileprivate init() {
            guard let env = try? Dotenv.load() else {
                print("Warning: Failed to load .env file; using defaults")
                self.network = "testnet"
                self.operator = nil
                self.runNonfreeTests = false
                return
            }

            self.network = env[Keys.network]?.stringValue ?? "testnet"
            self.runNonfreeTests = Self.parseBool(from: env[Keys.runNonfree]?.stringValue, defaultValue: false)

            if let op = Operator(env: env) {
                self.operator = op
            } else {
                self.operator = nil
                if runNonfreeTests {
                    print("Warning: Disabling non-free tests due to missing operator config")
                    self.runNonfreeTests = false
                }
            }
        }

        internal let network: String
        internal let operator: TestEnvironment.Operator?
        internal var runNonfreeTests: Bool
    }

    internal struct Operator {
        internal init?(env: Environment) {
            guard let keyStr = env[Keys.operatorKey]?.stringValue,
                  let accountIdStr = env[Keys.operatorAccountId]?.stringValue
            else {
                return nil
            }

            do {
                let accountId = try AccountId.fromString(accountIdStr)
                let key = try PrivateKey.fromString(keyStr)
                self.accountId = accountId
                self.privateKey = key
            } catch {
                print("Warning: Invalid operator config: \(error)")
                return nil
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
                var network: [String: AccountId] = [:]
                network[defaultLocalNodeAddress] = AccountId(num: 3)
                let client = try Client.forNetwork(network)
                self.client = client.setMirrorNetwork([defaultLocalMirrorNodeAddress])
            default:
                print("Warning: Unknown network '\(config.network)'; defaulting to testnet")
                self.client = Client.forTestnet()
            }
        } catch {
            print("Error initializing client for \(config.network): \(error); defaulting to testnet")
            self.client = Client.forTestnet()
        }

        if let op = config.operator {
            self.client.setOperator(op.accountId, op.privateKey)
        }
    }

    internal static let shared: TestEnvironment = TestEnvironment()
    internal static var nonFree: NonfreeTestEnvironment {
        get throws {
            if let inner = NonfreeTestEnvironment(shared) {
                return inner
            }

            throw XCTSkip("Test requires non-free environment, but only free tests are enabled")
        }
    }

    internal let client: Hiero.Client
    internal let config: Config
    internal let ratelimits: Ratelimit

    internal var operator: Operator? {
        config.operator
    }
}

internal struct NonfreeTestEnvironment {
    internal struct Config {
        fileprivate init?(base: TestEnvironment.Config) {
            guard base.runNonfreeTests, let op = base.operator else {
                return nil
            }
            self.network = base.network
            self.operator = op
        }

        internal let network: String
        internal let operator: TestEnvironment.Operator
    }

    private init?(_ env: TestEnvironment) {
        guard let config = Config(base: env.config) else {
            return nil
        }

        self.config = config
        self.client = env.client
        self.ratelimits = env.ratelimits
    }

    fileprivate static let shared: Self? = Self(.shared)

    internal let client: Hiero.Client
    internal let config: Config
    internal let ratelimits: Ratelimit

    internal var operator: TestEnvironment.Operator {
        config.operator
    }
}
