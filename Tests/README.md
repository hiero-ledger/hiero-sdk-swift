# Hiero SDK Swift Tests

This directory contains the test suite for the Hiero Swift SDK.

## Table of Contents

- [Test Targets](#test-targets)
- [Running Tests](#running-tests)
- [Environment Configuration](#environment-configuration)
- [Test Structure](#test-structure)
- [Writing Tests](#writing-tests)
- [Snapshot Testing](#snapshot-testing)
- [CI Configuration](#ci-configuration)

## Test Targets

| Target | Type | Network Required | Description |
|--------|------|------------------|-------------|
| `HieroUnitTests` | Unit | No | Tests SDK types, serialization, cryptography |
| `HieroIntegrationTests` | Integration | Yes | Tests against a Hiero network |
| `HieroTestSupport` | Support | N/A | Shared utilities for both test types |

### Unit Tests (`HieroUnitTests`)

Fast, isolated tests without network dependencies:

- Transaction serialization/deserialization
- Query protobuf conversion
- Property getters/setters
- Cryptographic operations
- Snapshot testing for protobufs

**Characteristics:**
- ⚡ Fast (milliseconds)
- 🔒 No network required
- 💰 Zero cost
- 🔁 Highly reproducible

### Integration Tests (`HieroIntegrationTests`)

End-to-end tests against a real Hiero network:

- Creating accounts, tokens, files, topics
- Executing transactions
- Querying network state
- Multi-signature flows
- Error handling with network responses

**Characteristics:**
- 🐌 Slower (seconds to minutes)
- 🌐 Requires network connectivity
- 💸 Costs HBAR
- 🔑 Requires operator credentials

## Running Tests

### Unit Tests Only (No Network Required)

```bash
swift test --filter HieroUnitTests
```

### Integration Tests Only (Network Required)

```bash
# Configure environment first (see below)
swift test --filter HieroIntegrationTests
```

### All Tests

```bash
swift test
```

### Specific Test

```bash
# Pattern: --filter <TestClass>/<testMethod>
swift test --filter AccountCreateTransactionUnitTests/test_Serialize
swift test --filter AccountCreateTransactionIntegrationTests/test_InitialBalanceAndKey
```

## Environment Configuration

### Required for Integration Tests

Create a `.env` file in the project root:

```bash
# Required: Operator account that pays transaction fees
HIERO_OPERATOR_ID=0.0.1234
HIERO_OPERATOR_KEY=302e020100300506032b657004220420...

# Optional: Environment type (defaults based on profile)
# Values: unit, local, testnet, previewnet, mainnet, custom
HIERO_ENVIRONMENT_TYPE=testnet
```

### Local Node Setup

For testing against [hiero-local-node](https://github.com/hiero-ledger/hiero-local-node):

```bash
HIERO_OPERATOR_ID=0.0.2
HIERO_OPERATOR_KEY=3030020100300706052b8104000a042204205bc004059ffa2943965d306f2c44d266255318b3775bacfec42a77ca83e998f2
HIERO_ENVIRONMENT_TYPE=local
```

#### Kubernetes DNS Configuration (Required for Node Update Tests)

When running against a local Kubernetes-based Hedera network (e.g., solo), some tests that trigger address book updates (like `NodeUpdateTransactionIntegrationTests`) require `/etc/hosts` entries for the Kubernetes internal DNS names.

Add the following to your `/etc/hosts` file:

```
127.0.0.1 network-node1-svc.solo.svc.cluster.local
127.0.0.1 network-node2-svc.solo.svc.cluster.local
```

**Why is this needed?**

The address book returned by the network contains internal Kubernetes DNS names. When the SDK updates its network configuration from the address book, it uses these hostnames. Without the `/etc/hosts` entries, the SDK cannot resolve these addresses when connecting to nodes.

The SDK automatically remaps `network-node2` from port 50211 to 51211 for local port-forwarding compatibility (since both hostnames resolve to 127.0.0.1 but need different ports).

#### Mirror Node Web3 API (Required for Mirror Node Contract Tests)

The `MirrorNodeContractIntegrationTests` require the mirror node's web3 API to be accessible on port 8545. This is a separate service from the main mirror node REST API (port 5600).

For local development with solo, ensure port 8545 is port-forwarded:

```bash
kubectl port-forward svc/mirror-1-web3 -n solo 8545:80 &
```

(The web3 service listens on port 80 internally, which is forwarded to local port 8545)

You can verify the web3 API is accessible:

```bash
curl -X POST http://localhost:8545/api/v1/contracts/call \
  -H "Content-Type: application/json" \
  -d '{"data":"", "to":"0x0000000000000000000000000000000000000001", "estimate":false}'
```

If the port-forward is not set up, the mirror node contract tests will fail with connection errors.

### Custom Network

```bash
HIERO_ENVIRONMENT_TYPE=custom
HIERO_CONSENSUS_NODES=127.0.0.1:50211,192.168.1.100:50211
HIERO_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4
HIERO_MIRROR_NODES=127.0.0.1:5600
```

### Test Profile

```bash
# Values: local, ciUnit, ciIntegration, development
# Default: local
HIERO_PROFILE=local
```

| Profile | Description |
|---------|-------------|
| `local` | Local development with local node (default) |
| `ciUnit` | CI unit tests - unit environment |
| `ciIntegration` | CI integration tests - local environment, verbose logging |
| `development` | Development against remote networks (testnet) |

### Feature Flags

```bash
# Maximum test duration in seconds (default: 300)
HIERO_MAX_DURATION=600

# Enable parallel test execution (default: false)
# Note: Parallel execution is not yet implemented
HIERO_PARALLEL=1

# Enable verbose logging (default: false)
HIERO_VERBOSE=1
```

### Cleanup Policy

Controls automatic cleanup of test resources. Cleanup can recover HBAR from accounts/contracts.

```bash
# Master cleanup switch (1 = all cleanup, 0 = no cleanup)
HIERO_ENABLE_CLEANUP=1

# Or fine-grained control:
HIERO_CLEANUP_ACCOUNTS=1    # Default: true (recovers HBAR)
HIERO_CLEANUP_CONTRACTS=1   # Default: true (recovers HBAR)
HIERO_CLEANUP_TOKENS=0      # Default: false (costs HBAR)
HIERO_CLEANUP_FILES=0       # Default: false (costs HBAR)
HIERO_CLEANUP_TOPICS=0      # Default: false (costs HBAR)
```

**Default Policy (economical):** Only cleans up accounts and contracts (recovers HBAR).

## Test Structure

```
Tests/
├── HieroUnitTests/              # Unit tests
│   ├── *UnitTests.swift         # Test files (126 files)
│   ├── __Snapshots__/           # Snapshot test data
│   └── AUDIT.md                 # Unit test documentation
│
├── HieroIntegrationTests/       # Integration tests
│   ├── Account/                 # Account transaction tests
│   ├── Contract/                # Contract transaction tests
│   ├── File/                    # File transaction tests
│   ├── Schedule/                # Schedule transaction tests
│   ├── Token/                   # Token transaction tests
│   ├── Topic/                   # Topic transaction tests
│   └── Transaction/             # Transaction query tests
│
└── HieroTestSupport/            # Shared test utilities
    ├── Assertions/              # Custom assertions (HieroAssertions.swift)
    ├── Base/                    # Base test classes
    │   ├── HieroTestCase.swift           # Root base class
    │   ├── HieroUnitTestCase.swift       # Unit test base class
    │   └── HieroIntegrationTestCase.swift # Integration test base class
    ├── Environment/             # Environment configuration
    │   ├── EnvironmentVariables.swift    # Environment variable reading
    │   ├── TestEnvironmentConfig.swift   # Configuration builder
    │   ├── TestProfile.swift             # Test profiles
    │   ├── CleanupPolicy.swift           # Cleanup configuration
    │   └── ...
    ├── Extensions/              # Test extensions
    ├── Fixtures/                # Test constants and data
    │   └── TestConstants.swift           # Shared test values
    ├── Helpers/                 # Integration test helpers
    │   ├── HieroIntegrationTestCase+Account.swift
    │   ├── HieroIntegrationTestCase+Token.swift
    │   ├── HieroIntegrationTestCase+Contract.swift
    │   ├── HieroIntegrationTestCase+File.swift
    │   ├── HieroIntegrationTestCase+Topic.swift
    │   ├── HieroIntegrationTestCase+Schedule.swift
    │   └── ResourceManager.swift         # Automatic resource cleanup
    └── Protocols/               # Test protocols
        ├── TransactionTestable.swift     # Transaction test helpers
        └── QueryTestable.swift           # Query test helpers
```

## Writing Tests

### Unit Tests

Basic unit test structure:

```swift
import HieroTestSupport
@testable import Hiero

internal final class MyTypeUnitTests: HieroUnitTestCase {
    func test_Something() {
        // Test code
    }
}
```

### Transaction Unit Tests

Use the `TransactionTestable` protocol for standardized transaction tests:

```swift
internal final class TokenDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenDeleteTransaction

    static func makeTransaction() throws -> TokenDeleteTransaction {
        try TokenDeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .tokenId(TestConstants.tokenId)
            .freeze()
            .sign(TestConstants.privateKey)
    }

    func test_Serialize() throws {
        try assertTransactionSerializes()  // Snapshot test
    }

    func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()  // Round-trip test
    }

    // Add custom tests as needed
    func test_GetSetTokenId() {
        let tx = TokenDeleteTransaction().tokenId("1.2.3")
        XCTAssertEqual(tx.tokenId, "1.2.3")
    }
}
```

### Query Unit Tests

Use the `QueryTestable` protocol for standardized query tests:

```swift
internal final class AccountBalanceQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() -> Proto_Query {
        AccountBalanceQuery(accountId: TestConstants.accountId)
            .toQueryProtobufWith(.init())
    }

    func test_Serialize() throws {
        try assertQuerySerializes()  // Snapshot test
    }
}
```

### Integration Tests

Integration tests use `HieroIntegrationTestCase` which provides:
- `testEnv` - The test environment with client and operator
- `resourceManager` - Automatic cleanup of created resources

```swift
import Hiero
import HieroTestSupport
import XCTest

internal final class AccountCreateTransactionIntegrationTests: HieroIntegrationTestCase {
    func test_BasicAccountCreation() async throws {
        // Use helper methods - resources are automatically cleaned up
        let (accountId, key) = try await createAccount()

        // Query and verify
        let info = try await AccountInfoQuery(accountId: accountId)
            .execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
    }

    func test_ExpectedError() async throws {
        // Use convenience assertion helpers
        await assertReceiptStatus(
            try await TokenCreateTransaction()
                .symbol("TEST")
                .treasuryAccountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .missingTokenName
        )
    }

    func test_PrecheckError() async throws {
        await assertPrecheckStatus(
            try await AccountCreateTransaction()
                .execute(testEnv.client),
            .keyRequired
        )
    }
}
```

### Available Test Constants

`TestConstants` provides commonly used test values:

```swift
// Keys
TestConstants.privateKey      // Ed25519 test private key
TestConstants.publicKey       // Corresponding public key

// Entity IDs
TestConstants.accountId       // "0.0.5009"
TestConstants.tokenId         // "0.3.5"
TestConstants.fileId          // "1.2.3"
TestConstants.topicId         // "4.4.4"
TestConstants.contractId      // "0.0.789"
TestConstants.scheduleId      // "0.0.555"

// Transaction setup
TestConstants.nodeAccountIds          // [5005, 5006]
TestConstants.transactionId           // Pre-configured transaction ID
TestConstants.validStart              // Timestamp for transaction ID

// Common values
TestConstants.initialBalance          // Hbar.fromTinybars(1000)
TestConstants.maxTransactionFee       // Hbar.fromTinybars(100_000)
TestConstants.autoRenewPeriod         // Duration.hours(10)
TestConstants.tokenName               // "ffff"
TestConstants.tokenSymbol             // "TEST"

// Integration test values
TestConstants.testAmount              // 100 (Int64)
TestConstants.testSmallHbarBalance    // Hbar(1)
TestConstants.testMediumHbarBalance   // Hbar(10)
TestConstants.contractBytecode        // Pre-compiled test contract
```

### Available Assertion Helpers

**For integration tests:**

```swift
// Assert a transaction fails with a specific receipt status
await assertReceiptStatus(
    try await transaction.execute(client).getReceipt(client),
    .invalidSignature
)

// Assert a transaction fails with a specific precheck status
await assertPrecheckStatus(
    try await transaction.execute(client),
    .keyRequired
)

// General HError assertion
await assertThrowsHErrorAsync(
    try await someOperation(),
    "expected error message"
) { error in
    // Custom error inspection
}
```

**For unit tests (via protocols):**

```swift
// TransactionTestable
try assertTransactionSerializes()  // Snapshot test
try assertTransactionRoundTrips()  // Bytes round-trip

// QueryTestable
try assertQuerySerializes()        // Snapshot test
```

### Integration Test Helpers

`HieroIntegrationTestCase` provides helper methods for creating test resources:

```swift
// Account helpers
let (accountId, key) = try await createAccount()
let (accountId, key) = try await createAccount(balance: Hbar(100))

// Token helpers
let tokenId = try await createFungibleToken()
let tokenId = try await createNft()

// File helpers
let fileId = try await createFile(contents: "test data".data(using: .utf8)!)

// Topic helpers
let topicId = try await createTopic()

// Contract helpers
let contractId = try await createContract()

// All resources created via helpers are automatically cleaned up!
```

## Snapshot Testing

Unit tests use [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) for serialization verification.

- Snapshots are stored in `__Snapshots__/<TestClassName>/`
- Each snapshot file is named after the test method
- To update a snapshot, delete the `.txt` file and re-run the test
- **Review snapshot changes carefully in PRs** - they represent serialization format changes

Example snapshot location:
```
Tests/HieroUnitTests/__Snapshots__/
└── AccountCreateTransactionUnitTests/
    ├── test_Serialize.1.txt
    └── test_Serialize2.1.txt
```

## CI Configuration

See `.github/workflows/` for CI configuration. Typical setup:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Unit Tests
        run: swift test --filter HieroUnitTests

  integration-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create .env file
        run: |
          echo "HIERO_OPERATOR_ID=${{ secrets.HIERO_OPERATOR_ID }}" >> .env
          echo "HIERO_OPERATOR_KEY=${{ secrets.HIERO_OPERATOR_KEY }}" >> .env
          echo "HIERO_PROFILE=ciIntegration" >> .env
          echo "HIERO_ENVIRONMENT_TYPE=testnet" >> .env
      - name: Run Integration Tests
        run: swift test --filter HieroIntegrationTests
```

## Naming Conventions

| Test Type | File Name | Class Name |
|-----------|-----------|------------|
| Unit | `AccountCreateTransactionUnitTests.swift` | `AccountCreateTransactionUnitTests` |
| Integration | `AccountCreateTransactionIntegrationTests.swift` | `AccountCreateTransactionIntegrationTests` |

## Best Practices

### Unit Tests

1. **No Network Calls** - Unit tests should never hit the network
2. **Fast Execution** - Each test should complete in milliseconds
3. **Use TestConstants** - Leverage shared test data
4. **Use Protocols** - `TransactionTestable` and `QueryTestable` reduce boilerplate
5. **Snapshot Testing** - Use for protobuf serialization verification

### Integration Tests

1. **Use Helper Methods** - `createAccount()`, `createToken()`, etc. handle cleanup
2. **Use Assertion Helpers** - `assertReceiptStatus()`, `assertPrecheckStatus()`
3. **Be HBAR Conscious** - All integration tests cost HBAR
4. **Handle Errors** - Test both success and failure paths
5. **Clean Up** - Resources are automatically cleaned up via `ResourceManager`

### General

1. **Descriptive Names** - `test_CreateAccountWithInitialBalance_Succeeds`
2. **Arrange-Act-Assert** - Structure tests clearly
3. **One Behavior Per Test** - Makes failures easier to diagnose

## Troubleshooting

### "Operator credentials not found"

Ensure `.env` file exists with `HIERO_OPERATOR_ID` and `HIERO_OPERATOR_KEY`.

### "Build errors after updating"

Try cleaning the build:
```bash
swift package clean
swift build
```

### Snapshot test failures

If a snapshot test fails unexpectedly:
1. Check if the serialization format intentionally changed
2. Delete the snapshot file and re-run to regenerate
3. Review the diff carefully before committing

### Integration test timeouts

Increase the timeout:
```bash
HIERO_MAX_DURATION=600  # 10 minutes
```
