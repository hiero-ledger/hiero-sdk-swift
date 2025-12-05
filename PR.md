# Test Suite Architecture Refactoring

## Summary

This PR represents a comprehensive refactoring of the Hiero SDK Swift test suite to establish a modern, maintainable, and well-documented testing architecture. The changes introduce a new shared test infrastructure (`HieroTestSupport`), establish clear separation between unit and integration tests, provide automatic resource management with intelligent cleanup, and eliminate significant code duplication through protocol-based testing patterns.

## Key Changes

### 🏗️ Test Target Restructuring

**Replaced** the old test targets (`HieroTests`, `HieroE2ETests`) with a clear three-target architecture:

| Target | Purpose | Network Required |
|--------|---------|------------------|
| `HieroUnitTests` | Fast, isolated unit tests | No |
| `HieroIntegrationTests` | End-to-end tests against Hiero network | Yes |
| `HieroTestSupport` | Shared utilities, base classes, fixtures | N/A |

```
Tests/
├── HieroUnitTests/              # Unit tests (126+ files)
│   ├── *UnitTests.swift
│   └── __Snapshots__/
├── HieroIntegrationTests/       # Integration tests (65 files)
│   ├── Account/
│   ├── Contract/
│   ├── File/
│   ├── Schedule/
│   ├── Token/
│   └── Topic/
└── HieroTestSupport/            # Shared infrastructure (27 files)
    ├── Assertions/
    ├── Base/
    ├── Environment/
    ├── Extensions/
    ├── Fixtures/
    ├── Helpers/
    └── Protocols/
```

---

## 🧱 Test Base Classes

### `HieroTestCase` - Root Base Class

The foundation for all tests. Handles environment configuration loading:

```swift
open class HieroTestCase: XCTestCase {
    open override func setUp() async throws {
        try await super.setUp()
        DotenvLoader.ensureLoaded()           // Load .env file
        try TestEnvironmentConfig.ensureLoaded()  // Validate configuration
    }
}
```

### `HieroUnitTestCase` - Unit Test Base Class

Base class for unit tests that don't require network access. Provides:

- **Re-exports** - Automatically imports `SnapshotTesting` and `HieroProtobufs` so test files only need `import HieroTestSupport`
- **Protocol Support** - Works with `TransactionTestable` and `QueryTestable` for standardized testing
- **No Network Setup** - No client creation, no operator credentials required

```swift
import HieroTestSupport
@testable import Hiero

internal final class TokenDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenDeleteTransaction
    
    static func makeTransaction() throws -> TokenDeleteTransaction {
        try TokenDeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .tokenId("1.2.3")
            .freeze()
            .sign(TestConstants.privateKey)
    }

    func test_Serialize() throws {
        try assertTransactionSerializes()  // Snapshot test from protocol
    }

    func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()  // Round-trip test from protocol
    }
}
```

### `HieroIntegrationTestCase` - Integration Test Base Class

Base class for integration tests that require network access. Provides:

- **Test Environment** (`testEnv`) - Pre-configured client with operator credentials
- **Resource Manager** - Automatic cleanup of test resources (accounts, tokens, contracts, etc.)
- **Service Helpers** - Extension methods for creating test resources (`createTestAccount()`, `createFungibleToken()`, etc.)

```swift
import Hiero
import HieroTestSupport

internal final class AccountCreateTransactionIntegrationTests: HieroIntegrationTestCase {
    func test_BasicAccountCreation() async throws {
        // Create account - automatically cleaned up after test
        let (accountId, key) = try await createTestAccount(initialBalance: Hbar(10))
        
        // Test the account
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        XCTAssertEqual(info.accountId, accountId)
    }
    
    func test_ExpectedError() async throws {
        // Use assertion helpers for error testing
        await assertReceiptStatus(
            try await TokenCreateTransaction()
                .symbol("TEST")
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .missingTokenName
        )
    }
}
```

---

## 🔄 ResourceManager

A new `actor`-based resource manager that handles automatic cleanup of test resources. Each test gets its own instance, enabling future parallel test execution.

### Purpose

- **Automatic Cleanup** - Resources created during tests are automatically deleted in `tearDown()`
- **Dependency-Aware** - Cleanup follows correct order (e.g., settle token balances before deleting accounts)
- **Economics-Aware** - Uses `CleanupPolicy` to only clean up resources worth the cost
- **HBAR Recovery** - Properly handles account deletion to recover locked HBAR

### CleanupPolicy

Selective cleanup based on economics:

```swift
public struct CleanupPolicy {
    public var cleanupAccounts: Bool   // ✅ Recovers HBAR - default ON
    public var cleanupContracts: Bool  // ✅ Can recover HBAR - default ON
    public var cleanupTokens: Bool     // ❌ Costs HBAR - default OFF
    public var cleanupFiles: Bool      // ❌ Costs HBAR - default OFF
    public var cleanupTopics: Bool     // ❌ Costs HBAR - default OFF
}
```

**Predefined Policies:**

| Policy | Accounts | Contracts | Tokens | Files | Topics | Use Case |
|--------|----------|-----------|--------|-------|--------|----------|
| `.none` | ❌ | ❌ | ❌ | ❌ | ❌ | CI with ephemeral networks |
| `.economical` | ✅ | ✅ | ❌ | ❌ | ❌ | Default - testnet development |
| `.all` | ✅ | ✅ | ✅ | ✅ | ✅ | Local node - keep clean, if desired |

**Economics:**
- Creating an account locks ~10 HBAR + 0.05 tx fee
- Deleting an account recovers ~10 HBAR - 0.001 tx fee
- **Net benefit: ~10 HBAR recovered per account cleaned up**
- Tokens/files/topics only cost HBAR to delete with no recovery

---

## ⚙️ Test Profiles

Predefined configurations for different testing scenarios. Set via `HIERO_PROFILE` environment variable.

### Available Profiles

| Profile | Environment | Use Case |
|---------|-------------|----------|
| `local` | Local node | Local development (default) |
| `ciUnit` | Unit only | CI unit test pipeline |
| `ciIntegration` | Local node | CI integration test pipeline |
| `development` | Testnet | Testing against remote networks |

### Profile Details

**`local`** (Default)
- For local development with a local Hiero node
- Supports both unit and integration tests (use `--filter` to select)
- Economical cleanup policy
- 300 second timeout

**`ciUnit`**
- For CI pipelines running only unit tests
- No network required
- Parallel execution enabled
- Verbose logging
- No cleanup (no resources created)
- 120 second timeout

**`ciIntegration`**
- For CI pipelines running integration tests
- Uses ephemeral local node
- Parallel execution enabled
- Verbose logging
- No cleanup (network destroyed after tests)
- 600 second timeout

**`development`**
- For testing against testnet/previewnet
- Economical cleanup (recover HBAR)
- Verbose logging
- 300 second timeout

---

## 🎛️ Feature Flags

Runtime configuration for test behavior. Can be set via environment variables to override profile defaults.

### Available Flags

| Flag | Environment Variable | Description | Default |
|------|---------------------|-------------|---------|
| `maxTestDuration` | `HIERO_MAX_DURATION` | Timeout per test (seconds) | 300 |
| `parallelExecution` | `HIERO_PARALLEL` | Enable parallel tests | false |
| `verboseLogging` | `HIERO_VERBOSE` | Detailed logging | false |
| `cleanupPolicy` | `HIERO_CLEANUP_*` | Resource cleanup behavior | economical |

### Cleanup Environment Variables

Fine-grained control over cleanup:

```bash
HIERO_ENABLE_CLEANUP=1      # Master switch (overrides all below)
HIERO_CLEANUP_ACCOUNTS=1    # Clean up accounts (recovers HBAR)
HIERO_CLEANUP_CONTRACTS=1   # Clean up contracts (recovers HBAR)
HIERO_CLEANUP_TOKENS=0      # Clean up tokens (costs HBAR)
HIERO_CLEANUP_FILES=0       # Clean up files (costs HBAR)
HIERO_CLEANUP_TOPICS=0      # Clean up topics (costs HBAR)
```

---

## 🧪 Integration Test Helper Architecture

Integration tests use a layered architecture where tests never touch `ResourceManager` directly:

```
┌─────────────────────────────────────────────────────────────┐
│                      Test Files                             │
│   test_CreateToken() { createFungibleToken(...) }          │
└───────────────────────────┬─────────────────────────────────┘
                            │ calls
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Service Helpers                           │
│   HieroIntegrationTestCase+Token.swift                     │
│   HieroIntegrationTestCase+Account.swift                   │
│   - Public API for tests                                    │
│   - Handles resource creation                               │
│   - Internally registers with ResourceManager               │
└───────────────────────────┬─────────────────────────────────┘
                            │ registers with
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   ResourceManager                           │
│   - Internal implementation detail                          │
│   - Never exposed to tests                                  │
│   - Handles cleanup orchestration                           │
└─────────────────────────────────────────────────────────────┘
```

### Service Helper Extensions

Each domain has its own extension file with helper methods:

| Extension | Helpers Provided |
|-----------|------------------|
| `+Account.swift` | `createTestAccount()`, `createAccount()`, `registerAccountForCleanup()` |
| `+Token.swift` | `createFungibleToken()`, `createNft()`, `associateToken()` |
| `+File.swift` | `createFile()`, `createTestFile()` |
| `+Topic.swift` | `createTopic()`, `createStandardTopic()` |
| `+Contract.swift` | `createContract()`, `createStandardContract()` |
| `+Schedule.swift` | `createSchedule()`, `standardScheduledTransfer()` |

---

## 📜 Protocol-Based Unit Testing

### `TransactionTestable` Protocol

For transaction unit tests. Provides default implementations for common test patterns:

```swift
public protocol TransactionTestable: XCTestCase {
    associatedtype TransactionType: Transaction
    static func makeTransaction() throws -> TransactionType
}

extension TransactionTestable {
    // Snapshot test for serialization
    public func assertTransactionSerializes() throws { ... }
    
    // Bytes round-trip test
    public func assertTransactionRoundTrips() throws { ... }
}
```

**Adopted by 47+ transaction test files**, eliminating duplicate `test_Serialize` and `test_ToFromBytes` implementations.

### `QueryTestable` Protocol

For query unit tests:

```swift
public protocol QueryTestable: XCTestCase {
    static func makeQueryProto() -> Proto_Query
}

extension QueryTestable {
    public func assertQuerySerializes() throws { ... }
}
```

**Adopted by 13+ query test files**.

---

## 🌍 Environment Variable System

### Renamed Variables (`TEST_*` → `HIERO_*`)

All environment variables now use the `HIERO_` prefix:

| Category | Variables |
|----------|-----------|
| **Operator** | `HIERO_OPERATOR_ID`, `HIERO_OPERATOR_KEY` |
| **Network** | `HIERO_ENVIRONMENT_TYPE`, `HIERO_CONSENSUS_NODES`, `HIERO_CONSENSUS_NODE_ACCOUNT_IDS`, `HIERO_MIRROR_NODES` |
| **Profile** | `HIERO_PROFILE` |
| **Features** | `HIERO_MAX_DURATION`, `HIERO_PARALLEL`, `HIERO_VERBOSE` |
| **Cleanup** | `HIERO_ENABLE_CLEANUP`, `HIERO_CLEANUP_ACCOUNTS`, `HIERO_CLEANUP_TOKENS`, etc. |

### Removed/Deprecated Variables

| Variable | Reason |
|----------|--------|
| `TEST_RUN_NONFREE` | Redundant - integration tests check for operator presence |
| `TEST_RUN_EXPENSIVE` | Simplified to unit vs integration tests |
| `TEST_NETWORK_REQUIRED` | Redundant with base class inheritance |
| `TEST_ENABLE_SNAPSHOTS` | Use swift-snapshot-testing's native recording |
| `LOCAL_NODE_*` | Unified into `HIERO_CONSENSUS_*` |

---

## ✅ New Assertion Helpers

Convenience functions for common integration test assertions:

```swift
// Assert a transaction fails with specific receipt status
await assertReceiptStatus(
    try await TokenCreateTransaction()
        .symbol("TEST")
        .execute(testEnv.client)
        .getReceipt(testEnv.client),
    .missingTokenName
)

// Assert a transaction fails with specific precheck status
await assertPrecheckStatus(
    try await AccountCreateTransaction()
        .execute(testEnv.client),
    .keyRequired
)

// General HError assertion
await assertThrowsHErrorAsync(
    try await someOperation()
) { error in
    // Custom error inspection
}
```

---

## 🔢 TestConstants Centralization

All test constants unified in `TestConstants.swift`:

```swift
// Keys
TestConstants.privateKey, TestConstants.publicKey

// Entity IDs
TestConstants.accountId, TestConstants.tokenId, TestConstants.fileId, etc.

// Transaction setup
TestConstants.nodeAccountIds, TestConstants.transactionId, TestConstants.validStart

// Token configuration
TestConstants.testTokenDecimals, TestConstants.testSmallInitialSupply, TestConstants.testMaxSupply

// Transfer amounts
TestConstants.testTransferAmount, TestConstants.testOperationAmount

// Account balances
TestConstants.testSmallHbarBalance, TestConstants.testMediumHbarBalance

// NFT metadata
TestConstants.testMetadata
```

---

## 🧹 Code Cleanup

### Dead Code Removed

| Component | Lines Removed |
|-----------|--------------|
| `HieroAssertions.swift` unused functions | ~200 lines |
| `XCTestCase+Hiero.swift` | 79 lines |
| `TestResources.swift` | 60 lines |
| `ResourceManager` unused types/methods | ~240 lines |
| Duplicate `Resources.swift` in unit tests | ~50 lines |

### Unit Test Migration

- All 126+ unit tests migrated to extend `HieroUnitTestCase`
- All files renamed from `*Tests.swift` to `*UnitTests.swift`
- All snapshot directories renamed to match new class names
- ~2,500 lines of duplicate code eliminated through protocol adoption

---

## Migration Guide

### Update `.env` Files

```bash
# Before
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
TEST_PROFILE=fullLocal

# After
HIERO_OPERATOR_ID=0.0.1234
HIERO_OPERATOR_KEY=302e...
HIERO_PROFILE=local
```

### Update CI/CD

Update environment variable names from `TEST_*` to `HIERO_*` in your CI configuration.

---

## Running Tests

```bash
# Unit tests only (no network required)
swift test --filter HieroUnitTests

# Integration tests only (requires .env configuration)
swift test --filter HieroIntegrationTests

# All tests
swift test
```

---

## Test Results

- ✅ **766+ unit tests passing**
- ✅ **All integration tests passing**
- ✅ **Build successful**

---

## Files Changed Summary

| Category | Files | Notes |
|----------|-------|-------|
| Test Support Infrastructure | 27 new files | Base classes, protocols, helpers, environment |
| Unit Tests | 126 renamed + migrated | `*Tests.swift` → `*UnitTests.swift` |
| Integration Tests | 65 files refactored | Use new helpers and base class |
| Old Test Files | 90+ deleted | `HieroTests/`, `HieroE2ETests/` removed |
| Source Code | 6 minor fixes | Duration, Timestamp, CustomFee, etc. |

---

## Benefits

1. **Clear Architecture** - Unit vs integration tests cleanly separated
2. **Automatic Resource Management** - No manual cleanup required in tests
3. **HBAR Efficient** - Intelligent cleanup recovers HBAR on testnet
4. **Less Boilerplate** - Protocols eliminate ~2,500 lines of duplicate code
5. **Single Source of Truth** - Centralized constants and defaults
6. **Easier Onboarding** - Clear patterns for writing new tests
7. **CI-Ready** - Profiles designed for different CI pipeline stages
8. **Future-Proof** - Per-test ResourceManager enables parallel execution
