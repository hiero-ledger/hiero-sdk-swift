# Test Suite Improvement Implementation Plan

**Date**: December 2024  
**Status**: Ready for Review

---

## Overview

This plan outlines four improvements to the test suite:

1. **File Naming Consistency** - Rename unit test files/classes to match integration test convention
2. **EntityIdTestable Protocol** - New protocol for standardizing entity ID tests
3. **Error Assertion Helpers** - New helpers for integration test error checking
4. **Test Documentation** - Create Tests/README.md and update root README

---

## Phase 1: File Naming Consistency

### Goal
Rename all unit test files and classes from `*Tests.swift` / `*Tests` to `*UnitTests.swift` / `*UnitTests` to match the integration test pattern.

### Convention
| Test Type | File Name | Class Name |
|-----------|-----------|------------|
| Unit | `AccountCreateTransactionUnitTests.swift` | `AccountCreateTransactionUnitTests` |
| Integration | `AccountCreateTransactionIntegrationTests.swift` | `AccountCreateTransactionIntegrationTests` |

### Files to Rename (126 files)

<details>
<summary>Click to expand full list</summary>

| Current File | New File |
|-------------|----------|
| `AccountAllowanceApproveTransactionTests.swift` | `AccountAllowanceApproveTransactionUnitTests.swift` |
| `AccountAllowanceDeleteTransactionTests.swift` | `AccountAllowanceDeleteTransactionUnitTests.swift` |
| `AccountBalanceQueryTests.swift` | `AccountBalanceQueryUnitTests.swift` |
| `AccountCreateTransactionTests.swift` | `AccountCreateTransactionUnitTests.swift` |
| `AccountDeleteTransactionTests.swift` | `AccountDeleteTransactionUnitTests.swift` |
| `AccountIdTests.swift` | `AccountIdUnitTests.swift` |
| `AccountInfoQueryTests.swift` | `AccountInfoQueryUnitTests.swift` |
| `AccountRecordsQueryTests.swift` | `AccountRecordsQueryUnitTests.swift` |
| `AccountUpdateTransactionTests.swift` | `AccountUpdateTransactionUnitTests.swift` |
| `AssessedCustomFeeTests.swift` | `AssessedCustomFeeUnitTests.swift` |
| `BatchTransactionTests.swift` | `BatchTransactionUnitTests.swift` |
| `ChunkedTransaction.swift` | `ChunkedTransactionUnitTests.swift` |
| `ClientTests.swift` | `ClientUnitTests.swift` |
| `ContractBytecodeQueryTests.swift` | `ContractBytecodeQueryUnitTests.swift` |
| `ContractCallQueryTests.swift` | `ContractCallQueryUnitTests.swift` |
| `ContractCreateTransactionTests.swift` | `ContractCreateTransactionUnitTests.swift` |
| `ContractDeleteTransactionTests.swift` | `ContractDeleteTransactionUnitTests.swift` |
| `ContractExecuteTransactionTests.swift` | `ContractExecuteTransactionUnitTests.swift` |
| `ContractFunctionParametersTests.swift` | `ContractFunctionParametersUnitTests.swift` |
| `ContractFunctionResultTests.swift` | `ContractFunctionResultUnitTests.swift` |
| `ContractFunctionSelectorTests.swift` | `ContractFunctionSelectorUnitTests.swift` |
| `ContractIdTests.swift` | `ContractIdUnitTests.swift` |
| `ContractInfoQueryTests.swift` | `ContractInfoQueryUnitTests.swift` |
| `ContractInfoTests.swift` | `ContractInfoUnitTests.swift` |
| `ContractLogInfoTests.swift` | `ContractLogInfoUnitTests.swift` |
| `ContractNonceInfoTests.swift` | `ContractNonceInfoUnitTests.swift` |
| `ContractUpdateTransactionTests.swift` | `ContractUpdateTransactionUnitTests.swift` |
| `CryptoAesTests.swift` | `CryptoAesUnitTests.swift` |
| `CryptoPemTests.swift` | `CryptoPemUnitTests.swift` |
| `CryptoSha2Tests.swift` | `CryptoSha2UnitTests.swift` |
| `CryptoSha3Tests.swift` | `CryptoSha3UnitTests.swift` |
| `CustomFeeLimitTests.swift` | `CustomFeeLimitUnitTests.swift` |
| `CustomFeeTests.swift` | `CustomFeeUnitTests.swift` |
| `DelegateContractIdTests.swift` | `DelegateContractIdUnitTests.swift` |
| `DurationTests.swift` | `DurationUnitTests.swift` |
| `EntityIdTests.swift` | `EntityIdUnitTests.swift` |
| `EthereumDataTests.swift` | `EthereumDataUnitTests.swift` |
| `EthereumTransactionTests.swift` | `EthereumTransactionUnitTests.swift` |
| `ExchangeRatesTests.swift` | `ExchangeRatesUnitTests.swift` |
| `FeeScheduleTests.swift` | `FeeScheduleUnitTests.swift` |
| `FeeSchedulesTests.swift` | `FeeSchedulesUnitTests.swift` |
| `FileAppendTransactionTests.swift` | `FileAppendTransactionUnitTests.swift` |
| `FileContentsQueryTests.swift` | `FileContentsQueryUnitTests.swift` |
| `FileContentsResponseTests.swift` | `FileContentsResponseUnitTests.swift` |
| `FileCreateTransactionTests.swift` | `FileCreateTransactionUnitTests.swift` |
| `FileDeleteTransaction.swift` | `FileDeleteTransactionUnitTests.swift` |
| `FileIdTests.swift` | `FileIdUnitTests.swift` |
| `FileInfoQueryTests.swift` | `FileInfoQueryUnitTests.swift` |
| `FileInfoTests.swift` | `FileInfoUnitTests.swift` |
| `FileUpdateTransactionTests.swift` | `FileUpdateTransactionUnitTests.swift` |
| `FreezeTransactionTests.swift` | `FreezeTransactionUnitTests.swift` |
| `HbarTests.swift` | `HbarUnitTests.swift` |
| `KeyListTests.swift` | `KeyListUnitTests.swift` |
| `KeyTests.swift` | `KeyUnitTests.swift` |
| `LedgerIdTests.swift` | `LedgerIdUnitTests.swift` |
| `MirrorNodeContractQueryTests.swift` | `MirrorNodeContractQueryUnitTests.swift` |
| `MnemonicTests.swift` | `MnemonicUnitTests.swift` |
| `NetworkVersionInfoTests.swift` | `NetworkVersionInfoUnitTests.swift` |
| `NftIdTests.swift` | `NftIdUnitTests.swift` |
| `NodeCreateTransactionTests.swift` | `NodeCreateTransactionUnitTests.swift` |
| `NodeDeleteTransactionTests.swift` | `NodeDeleteTransactionUnitTests.swift` |
| `NodeUpdateTransactionTests.swift` | `NodeUpdateTransactionUnitTests.swift` |
| `PrivateKeyTests.swift` | `PrivateKeyUnitTests.swift` |
| `PrngTransactionTests.swift` | `PrngTransactionUnitTests.swift` |
| `ProxyStakerTests.swift` | `ProxyStakerUnitTests.swift` |
| `PublicKeyTests.swift` | `PublicKeyUnitTests.swift` |
| `RlpTests.swift` | `RlpUnitTests.swift` |
| `ScheduleCreateTransactionTests.swift` | `ScheduleCreateTransactionUnitTests.swift` |
| `ScheduleDeleteTransactionTests.swift` | `ScheduleDeleteTransactionUnitTests.swift` |
| `ScheduleIdTests.swift` | `ScheduleIdUnitTests.swift` |
| `ScheduleInfoQueryTests.swift` | `ScheduleInfoQueryUnitTests.swift` |
| `ScheduleInfoTests.swift` | `ScheduleInfoUnitTests.swift` |
| `ScheduleSignTransactionTests.swift` | `ScheduleSignTransactionUnitTests.swift` |
| `SemanticVersionTests.swift` | `SemanticVersionUnitTests.swift` |
| `SignatureTests.swift` | `SignatureUnitTests.swift` |
| `StakingInfoTests.swift` | `StakingInfoUnitTests.swift` |
| `StatusTests.swift` | `StatusUnitTests.swift` |
| `SystemDeleteTransactionTests.swift` | `SystemDeleteTransactionUnitTests.swift` |
| `SystemUndeleteTransactionTests.swift` | `SystemUndeleteTransactionUnitTests.swift` |
| `TokenAirdropTransactionTests.swift` | `TokenAirdropTransactionUnitTests.swift` |
| `TokenAllowanceTests.swift` | `TokenAllowanceUnitTests.swift` |
| `TokenAssociateTransactionTests.swift` | `TokenAssociateTransactionUnitTests.swift` |
| `TokenAssociationTests.swift` | `TokenAssociationUnitTests.swift` |
| `TokenBurnTransactionTests.swift` | `TokenBurnTransactionUnitTests.swift` |
| `TokenCancelAirdropTransactionTests.swift` | `TokenCancelAirdropTransactionUnitTests.swift` |
| `TokenClaimAirdropTransactionTests.swift` | `TokenClaimAirdropTransactionUnitTests.swift` |
| `TokenCreateTransactionTests.swift` | `TokenCreateTransactionUnitTests.swift` |
| `TokenDeleteTransactionTests.swift` | `TokenDeleteTransactionUnitTests.swift` |
| `TokenDissociateTransactionTests.swift` | `TokenDissociateTransactionUnitTests.swift` |
| `TokenFeeScheduleUpdateTransactionTests.swift` | `TokenFeeScheduleUpdateTransactionUnitTests.swift` |
| `TokenFreezeTransactionTests.swift` | `TokenFreezeTransactionUnitTests.swift` |
| `TokenGrantKycTransactionTests.swift` | `TokenGrantKycTransactionUnitTests.swift` |
| `TokenIdTests.swift` | `TokenIdUnitTests.swift` |
| `TokenInfoQueryTests.swift` | `TokenInfoQueryUnitTests.swift` |
| `TokenInfoTests.swift` | `TokenInfoUnitTests.swift` |
| `TokenMintTransactionTests.swift` | `TokenMintTransactionUnitTests.swift` |
| `TokenNftAllowanceTests.swift` | `TokenNftAllowanceUnitTests.swift` |
| `TokenNftInfoQueryTests.swift` | `TokenNftInfoQueryUnitTests.swift` |
| `TokenNftInfoTests.swift` | `TokenNftInfoUnitTests.swift` |
| `TokenNftTransferTests.swift` | `TokenNftTransferUnitTests.swift` |
| `TokenPauseTransactionTests.swift` | `TokenPauseTransactionUnitTests.swift` |
| `TokenRejectTransaction.swift` | `TokenRejectTransactionUnitTests.swift` |
| `TokenRevokeKycTransactionTests.swift` | `TokenRevokeKycTransactionUnitTests.swift` |
| `TokenTypeTests.swift` | `TokenTypeUnitTests.swift` |
| `TokenUnfreezeTransactionTests.swift` | `TokenUnfreezeTransactionUnitTests.swift` |
| `TokenUnpauseTransactionTests.swift` | `TokenUnpauseTransactionUnitTests.swift` |
| `TokenUpdateTransactionTests.swift` | `TokenUpdateTransactionUnitTests.swift` |
| `TokenWipeTransactionTests.swift` | `TokenWipeTransactionUnitTests.swift` |
| `TopicCreateTransactionTests.swift` | `TopicCreateTransactionUnitTests.swift` |
| `TopicDeleteTransactionTests.swift` | `TopicDeleteTransactionUnitTests.swift` |
| `TopicIdTests.swift` | `TopicIdUnitTests.swift` |
| `TopicInfoQueryTests.swift` | `TopicInfoQueryUnitTests.swift` |
| `TopicInfoTests.swift` | `TopicInfoUnitTests.swift` |
| `TopicMessageQueryTests.swift` | `TopicMessageQueryUnitTests.swift` |
| `TopicMessageSubmitTransactionTests.swift` | `TopicMessageSubmitTransactionUnitTests.swift` |
| `TopicMessageTests.swift` | `TopicMessageUnitTests.swift` |
| `TopicUpdateTransactionTests.swift` | `TopicUpdateTransactionUnitTests.swift` |
| `TransactionChunkInfoTests.swift` | `TransactionChunkInfoUnitTests.swift` |
| `TransactionFeeScheduleTests.swift` | `TransactionFeeScheduleUnitTests.swift` |
| `TransactionIdTests.swift` | `TransactionIdUnitTests.swift` |
| `TransactionReceiptQuery.swift` | `TransactionReceiptQueryUnitTests.swift` |
| `TransactionReceiptTests.swift` | `TransactionReceiptUnitTests.swift` |
| `TransactionRecordQueryTests.swift` | `TransactionRecordQueryUnitTests.swift` |
| `TransactionRecordTests.swift` | `TransactionRecordUnitTests.swift` |
| `TransactionTests.swift` | `TransactionUnitTests.swift` |
| `TransferTransactionTests.swift` | `TransferTransactionUnitTests.swift` |

</details>

### Implementation Steps

1. **For each file** (can be batched in git):
   - Rename the file from `*Tests.swift` to `*UnitTests.swift`
   - Update the class name inside from `*Tests` to `*UnitTests`

2. **Update snapshot directories**: The `__Snapshots__` folders reference test class names. These will need to be renamed:
   - `__Snapshots__/AccountIdTests/` → `__Snapshots__/AccountIdUnitTests/`
   - etc.

3. **Update AUDIT.md**: Update any references to old class names

### Estimated Time
~2-3 hours (mostly mechanical renaming)

### Risk
- **Low**: File renames are straightforward
- **Snapshot directories must be renamed** or tests will fail to find existing snapshots

---

## Phase 2: EntityIdTestable Protocol

### Goal
Create a protocol that standardizes common patterns in entity ID tests.

### Candidate Files
The following entity ID test files share common patterns:

| File | Shared Methods |
|------|----------------|
| `AccountIdTests.swift` | `test_Parse`, `test_ToFromBytesRoundtrip`, `test_FromSolidityAddress`, `test_ToSolidityAddress` |
| `ContractIdTests.swift` | `test_Parse`, `test_ToFromBytes`, `test_FromSolidityAddress`, `test_ToSolidityAddress` |
| `FileIdTests.swift` | `test_Parse`, `test_ToFromBytes`, `test_FromSolidityAddress`, `test_ToSolidityAddress` |
| `TokenIdTests.swift` | `test_Parse`, `test_ToFromBytes` |
| `TopicIdTests.swift` | `test_Parse`, `test_ToFromBytes` |
| `ScheduleIdTests.swift` | `test_Parse`, `test_ToFromBytes` |
| `NftIdTests.swift` | `test_Parse`, `test_ToFromBytes` |
| `DelegateContractIdTests.swift` | `test_Parse`, `test_ToFromBytes`, `test_FromSolidityAddress`, `test_ToSolidityAddress` |

### Protocol Design

```swift
// Tests/HieroTestSupport/Protocols/EntityIdTestable.swift

/// Protocol for standardizing entity ID unit tests.
///
/// Conforming types provide factory methods for creating test entity IDs.
/// The protocol provides default implementations for common test patterns.
public protocol EntityIdTestable: HieroUnitTestCase {
    /// The entity ID type being tested (e.g., AccountId, TokenId)
    associatedtype EntityIdType: EntityId
    
    /// A valid string representation for parsing tests (e.g., "0.0.1001")
    static var validIdString: String { get }
    
    /// Creates an entity ID with the given num for roundtrip tests
    static func makeEntityId(num: UInt64) -> EntityIdType
}

extension EntityIdTestable {
    /// Standard test for parsing an entity ID from string
    public func assertEntityIdParses(
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) throws {
        let entityId = try EntityIdType.fromString(Self.validIdString)
        SnapshotTesting.assertSnapshot(of: entityId, as: .description, file: file, testName: testName, line: line)
    }
    
    /// Standard test for bytes roundtrip
    public func assertEntityIdBytesRoundtrip(
        num: UInt64 = 1001,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let entityId = Self.makeEntityId(num: num)
        let roundtripped = try EntityIdType.fromBytes(entityId.toBytes())
        XCTAssertEqual(entityId, roundtripped, file: file, line: line)
    }
}
```

### Usage Example

```swift
internal final class TokenIdUnitTests: HieroUnitTestCase, EntityIdTestable {
    typealias EntityIdType = TokenId
    
    static var validIdString: String { "0.0.1001" }
    
    static func makeEntityId(num: UInt64) -> TokenId {
        TokenId(num: num)
    }
    
    func test_Parse() throws {
        try assertEntityIdParses()
    }
    
    func test_ToFromBytes() throws {
        try assertEntityIdBytesRoundtrip()
    }
    
    // Type-specific tests remain manual
    func test_NftId() {
        // ...
    }
}
```

### Implementation Steps

1. Create `Tests/HieroTestSupport/Protocols/EntityIdTestable.swift`
2. Migrate one test file (e.g., `TokenIdTests.swift`) as proof of concept
3. Migrate remaining entity ID test files

### Estimated Time
~1 hour

### Risk
- **Low**: Protocol is additive, doesn't break existing tests
- Entity ID types must conform to a common `EntityId` protocol (verify this exists)

---

## Phase 3: Error Assertion Helpers

### Goal
Add helper functions to reduce boilerplate in integration test error assertions.

### Current Pattern (Repeated 50+ times)

```swift
await assertThrowsHErrorAsync(
    try await SomeTransaction().execute(testEnv.client).getReceipt(testEnv.client),
    "expected error message"
) { error in
    guard case .receiptStatus(let status, transactionId: _) = error.kind else {
        XCTFail("`\(error.kind)` is not `.receiptStatus`")
        return
    }
    XCTAssertEqual(status, .expectedStatus)
}
```

### Proposed Helpers

```swift
// Tests/HieroTestSupport/Assertions/HieroAssertions.swift

/// Assert that an async expression throws an HError with a specific receipt status.
///
/// This is a convenience wrapper for the common pattern of asserting receipt status errors.
///
/// ## Usage
/// ```swift
/// await assertReceiptStatus(
///     try await TokenCreateTransaction()
///         .execute(testEnv.client)
///         .getReceipt(testEnv.client),
///     .missingTokenName
/// )
/// ```
public func assertReceiptStatus<T>(
    _ expression: @autoclosure () async throws -> T,
    _ expectedStatus: Status,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) async {
    await assertThrowsHErrorAsync(expression, message(), file: file, line: line) { error in
        guard case .receiptStatus(let status, transactionId: _) = error.kind else {
            XCTFail(
                "Expected receiptStatus error, got \(error.kind)" + 
                (message().isEmpty ? "" : " - \(message())"),
                file: file, 
                line: line
            )
            return
        }
        XCTAssertEqual(status, expectedStatus, file: file, line: line)
    }
}

/// Assert that an async expression throws an HError with a specific precheck status.
///
/// This is a convenience wrapper for the common pattern of asserting precheck status errors.
///
/// ## Usage
/// ```swift
/// await assertPrecheckStatus(
///     try await AccountCreateTransaction().execute(testEnv.client),
///     .keyRequired
/// )
/// ```
public func assertPrecheckStatus<T>(
    _ expression: @autoclosure () async throws -> T,
    _ expectedStatus: Status,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) async {
    await assertThrowsHErrorAsync(expression, message(), file: file, line: line) { error in
        guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
            XCTFail(
                "Expected transactionPreCheckStatus error, got \(error.kind)" +
                (message().isEmpty ? "" : " - \(message())"),
                file: file, 
                line: line
            )
            return
        }
        XCTAssertEqual(status, expectedStatus, file: file, line: line)
    }
}
```

### Usage After (Much Cleaner)

```swift
// Before: ~10 lines
await assertThrowsHErrorAsync(
    try await TokenCreateTransaction()
        .symbol(TestConstants.tokenSymbol)
        .treasuryAccountId(testEnv.operator.accountId)
        .execute(testEnv.client)
        .getReceipt(testEnv.client),
    "expected error creating token"
) { error in
    guard case .receiptStatus(let status, transactionId: _) = error.kind else {
        XCTFail("`\(error.kind)` is not `.receiptStatus`")
        return
    }
    XCTAssertEqual(status, .missingTokenName)
}

// After: 1 line
await assertReceiptStatus(
    try await TokenCreateTransaction()
        .symbol(TestConstants.tokenSymbol)
        .treasuryAccountId(testEnv.operator.accountId)
        .execute(testEnv.client)
        .getReceipt(testEnv.client),
    .missingTokenName
)
```

### Implementation Steps

1. Add `assertReceiptStatus` and `assertPrecheckStatus` to `HieroAssertions.swift`
2. (Optional) Migrate existing integration tests to use new helpers (can be gradual)

### Estimated Time
~15 minutes to add helpers, migration is optional/gradual

### Risk
- **None**: Additive change, existing code continues to work

---

## Phase 4: Test Documentation

### Goal
Create comprehensive test documentation in `Tests/README.md` and update root `README.md`.

### Tests/README.md Content

```markdown
# Hiero SDK Swift Tests

This directory contains the test suite for the Hiero Swift SDK.

## Test Targets

| Target | Type | Network Required | Description |
|--------|------|------------------|-------------|
| `HieroUnitTests` | Unit | No | Tests SDK types, serialization, cryptography |
| `HieroIntegrationTests` | Integration | Yes | Tests against a Hiero network |
| `HieroTestSupport` | Support | N/A | Shared utilities for both test types |

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

# Required: Environment type
# Values: local, testnet, previewnet, mainnet, custom
HIERO_ENVIRONMENT_TYPE=testnet
```

### Local Node Setup

For testing against [hiero-local-node](https://github.com/hiero-ledger/hiero-local-node):

```bash
HIERO_OPERATOR_ID=0.0.2
HIERO_OPERATOR_KEY=3030020100300706052b8104000a042204205bc004059ffa2943965d306f2c44d266255318b3775bacfec42a77ca83e998f2
HIERO_ENVIRONMENT_TYPE=local
```

### Custom Network

```bash
HIERO_ENVIRONMENT_TYPE=custom
HIERO_CONSENSUS_NODES=127.0.0.1:50211,192.168.1.100:50211
HIERO_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4
HIERO_MIRROR_NODES=127.0.0.1:5600
```

## Optional Environment Variables

### Test Profile

```bash
# Values: local, ciUnit, ciIntegration, development
# Default: local
HIERO_PROFILE=local
```

| Profile | Description |
|---------|-------------|
| `local` | Local development (default) |
| `ciUnit` | CI unit tests - parallel execution, verbose logging |
| `ciIntegration` | CI integration tests - parallel, verbose, no cleanup |
| `development` | Development against remote networks |

### Feature Flags

```bash
# Maximum test duration in seconds (default: 300)
HIERO_MAX_DURATION=600

# Enable parallel test execution (default: false)
HIERO_PARALLEL=1

# Enable verbose logging (default: false)
HIERO_VERBOSE=1
```

### Cleanup Policy

Controls automatic cleanup of test resources. Cleanup recovers HBAR from accounts/contracts.

```bash
# Master cleanup switch (1 = all cleanup, 0 = no cleanup)
HIERO_ENABLE_CLEANUP=1

# Or fine-grained control:
HIERO_CLEANUP_ACCOUNTS=1    # Recommended: recovers HBAR
HIERO_CLEANUP_CONTRACTS=1   # Recommended: recovers HBAR
HIERO_CLEANUP_TOKENS=0      # Optional: costs HBAR
HIERO_CLEANUP_FILES=0       # Optional: costs HBAR  
HIERO_CLEANUP_TOPICS=0      # Optional: costs HBAR
```

**Default Policy (economical)**: Only clean up accounts and contracts (recovers HBAR).

## Test Structure

```
Tests/
├── HieroUnitTests/           # Unit tests
│   ├── *UnitTests.swift      # Test files
│   └── __Snapshots__/        # Snapshot test data
├── HieroIntegrationTests/    # Integration tests
│   ├── Account/              # Account transaction tests
│   ├── Contract/             # Contract transaction tests
│   ├── File/                 # File transaction tests
│   ├── Schedule/             # Schedule transaction tests
│   ├── Token/                # Token transaction tests
│   ├── Topic/                # Topic transaction tests
│   └── Transaction/          # Transaction query tests
└── HieroTestSupport/         # Shared test utilities
    ├── Assertions/           # Custom assertions
    ├── Base/                 # Base test classes
    ├── Environment/          # Environment configuration
    ├── Extensions/           # Test extensions
    ├── Fixtures/             # Test constants and data
    ├── Helpers/              # Integration test helpers
    └── Protocols/            # Test protocols
```

## Writing Tests

### Unit Tests

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

```swift
internal final class MyTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = MyTransaction
    
    static func makeTransaction() throws -> MyTransaction {
        try MyTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .freeze()
            .sign(TestConstants.privateKey)
    }
    
    func test_Serialize() throws {
        try assertTransactionSerializes()
    }
    
    func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }
}
```

### Query Unit Tests

```swift
internal final class MyQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() -> Proto_Query {
        MyQuery(someId: 5005).toQueryProtobufWith(.init())
    }
    
    func test_Serialize() throws {
        try assertQuerySerializes()
    }
}
```

### Integration Tests

```swift
import Hiero
import HieroTestSupport
import XCTest

internal final class MyTransactionIntegrationTests: HieroIntegrationTestCase {
    func test_BasicOperation() async throws {
        // Resources created with createAccount/createToken/etc are automatically cleaned up
        let (accountId, key) = try await createTestAccount()
        
        // Test code
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        XCTAssertEqual(info.accountId, accountId)
    }
    
    func test_ExpectedError() async throws {
        // Use error assertion helpers
        await assertReceiptStatus(
            try await SomeTransaction().execute(testEnv.client).getReceipt(testEnv.client),
            .expectedStatus
        )
    }
}
```

## Snapshot Testing

Unit tests use [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) for serialization verification.

- Snapshots are stored in `__Snapshots__/<TestClassName>/`
- To update snapshots, delete the `.txt` file and re-run the test
- Review snapshot changes carefully in PRs

## CI Configuration

See `.github/workflows/` for CI configuration. The CI runs:
- Unit tests on every PR
- Integration tests on merge to main (with testnet credentials)
```

### Root README.md Update

Update the Testing section in the root README:

```markdown
### Testing

See [Tests/README.md](./Tests/README.md) for comprehensive testing documentation.

**Quick Start:**

```bash
# Unit tests (no network required)
swift test --filter HieroUnitTests

# Integration tests (requires .env configuration)
swift test --filter HieroIntegrationTests

# All tests
swift test
```
```

### Implementation Steps

1. Create `Tests/README.md` with full documentation
2. Update root `README.md` to reference Tests/README.md

### Estimated Time
~30 minutes

### Risk
- **None**: Documentation only

---

## Execution Order

| Phase | Description | Estimated Time | Dependencies |
|-------|-------------|----------------|--------------|
| 1 | File Naming | 2-3 hours | None |
| 2 | EntityIdTestable | 1 hour | Phase 1 (class names) |
| 3 | Error Helpers | 15 minutes | None |
| 4 | Documentation | 30 minutes | Phase 1 (for accurate docs) |

**Recommended Order**: Phase 3 → Phase 4 → Phase 1 → Phase 2

- Phases 3 & 4 are quick wins with no dependencies
- Phase 1 is the largest change but straightforward
- Phase 2 builds on Phase 1's renamed files

---

## Checklist

### Phase 1: File Naming ✅
- [x] Rename all 126 unit test files
- [x] Update all 126 class names
- [x] Rename all 99 `__Snapshots__` directories
- [x] Fix internal class references (BatchTransactionTests)
- [x] Run tests to verify

### Phase 2: EntityIdTestable
- [ ] Create `EntityIdTestable.swift` in HieroTestSupport/Protocols
- [ ] Verify `EntityId` protocol exists in Hiero
- [ ] Migrate `TokenIdUnitTests.swift` as proof of concept
- [ ] Migrate remaining entity ID tests (7-8 files)

### Phase 3: Error Helpers ✅
- [x] Add `assertReceiptStatus` to HieroAssertions.swift
- [x] Add `assertPrecheckStatus` to HieroAssertions.swift
- [x] Add documentation comments
- [ ] Run integration tests to verify

### Phase 4: Documentation ✅
- [x] Create/Update Tests/README.md with comprehensive documentation
- [x] Update root README.md to reference Tests/README.md
- [x] Document all environment variables (HIERO_* prefix)
