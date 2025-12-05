# Integration Test Architecture Refactoring Plan

## Overview

This document outlines the plan to refactor `HieroTestSupport` and `HieroIntegrationTests` to improve maintainability, reduce dead code, and establish clear layering.

---

## Design Principles

### 1. Tests Never Touch ResourceManager Directly

```
┌─────────────────────────────────────────────────────────────┐
│                      Test Files                             │
│   test_CreateToken() { createToken(...) }                   │
└───────────────────────────┬─────────────────────────────────┘
                            │ calls
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Service Helpers                           │
│   TokenHelper, AccountHelper, FileHelper, etc.              │
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

### 2. Service Helpers Own All Resource Logic

All resource creation/registration logic lives in `<Service>Helper.swift` files, NOT in `HieroIntegrationTestCase`. The base class is minimal.

### 3. ResourceManager Per-Test Instance

Each test gets its own ResourceManager instance to support future parallel test execution. Tests never access it directly - helpers do.

---

## Target Architecture

```
Tests/
├── HieroTestSupport/
│   ├── Base/
│   │   ├── HieroTestCase.swift              # Base (config loading)
│   │   ├── HieroIntegrationTestCase.swift   # Minimal: setup/teardown + testEnv + resourceManager
│   │   └── HieroUnitTestCase.swift          # Snapshot helpers
│   │
│   ├── Helpers/
│   │   ├── ResourceManager.swift            # Per-test instance, cleanup orchestration ONLY
│   │   │                                    # (includes CleanupPriority, TestAccount, TestContract)
│   │   │
│   │   ├── HieroIntegrationTestCase+Account.swift   # ALL account logic
│   │   ├── HieroIntegrationTestCase+Token.swift     # ALL token logic
│   │   ├── HieroIntegrationTestCase+Contract.swift  # ALL contract logic
│   │   ├── HieroIntegrationTestCase+File.swift      # ALL file logic
│   │   ├── HieroIntegrationTestCase+Topic.swift     # ALL topic logic
│   │   └── HieroIntegrationTestCase+Schedule.swift  # ALL schedule logic
│   │
│   ├── Fixtures/
│   │   ├── TestConstants.swift              # All constants (updated)
│   │   ├── TestKeys.swift
│   │   └── TestResources.swift
│   │
│   └── Environment/                          # Unchanged
│
├── HieroIntegrationTests/
│   ├── Account/                              # Tests only, NO helpers
│   ├── Contract/
│   ├── File/
│   ├── Schedule/
│   ├── Token/
│   └── Topic/
```

---

## Component Details

### HieroIntegrationTestCase (Minimal)

```swift
/// Minimal base class - just setup/teardown, environment, and resourceManager
open class HieroIntegrationTestCase: HieroTestCase {
    /// Test environment with operator credentials
    public var testEnv: IntegrationTestEnvironment!
    
    /// Resource manager for automatic cleanup (internal - helpers use this, not tests)
    internal var resourceManager: ResourceManager!
    
    open override func setUp() async throws {
        try await super.setUp()
        testEnv = try await IntegrationTestEnvironment.create()
        
        let config = try TestEnvironmentConfig.shared
        resourceManager = ResourceManager(
            client: testEnv.client,
            operatorAccountId: testEnv.operator.accountId,
            operatorPrivateKey: testEnv.operator.privateKey,
            cleanupPolicy: config.features.cleanupPolicy
        )
    }
    
    open override func tearDown() async throws {
        if let manager = resourceManager {
            try await manager.cleanup()
        }
        try await super.tearDown()
    }
}
```

~50 lines total.

### ResourceManager (Cleanup Only)

```swift
public actor ResourceManager {
    private var cleanupActions: [CleanupAction] = []
    private var wipeKeys: [TokenId: PrivateKey] = [:]
    private var pauseKeys: [TokenId: PrivateKey] = [:]
    
    private let client: Client
    private let operatorAccountId: AccountId
    private let operatorPrivateKey: PrivateKey
    private let cleanupPolicy: CleanupPolicy
    
    // Internal types (used only by ResourceManager)
    // TestAccount, TestContract - keep these for internal cleanup logic
    
    // MARK: - Registration (internal - only helpers call these)
    
    internal func registerCleanup(priority: CleanupPriority, action: @escaping () async throws -> Void)
    internal func registerWipeKey(_ wipeKey: PrivateKey, for tokenId: TokenId)
    internal func registerPauseKey(_ pauseKey: PrivateKey, for tokenId: TokenId)
    internal func registerAccount(_ accountId: AccountId, keys: [PrivateKey])
    internal func registerContract(_ contractId: ContractId, adminKeys: [PrivateKey])
    
    // MARK: - Cleanup (internal - called by tearDown)
    
    internal func cleanup() async throws
    
    // MARK: - Internal cleanup logic
    
    private func settleTokenBalances(for account: TestAccount) async throws
    private func deleteAccount(_ account: TestAccount) async throws
    private func deleteContract(_ contract: TestContract) async throws
    internal func unpauseTokenIfNeeded(_ tokenId: TokenId) async throws
}
```

~150-200 lines total (down from 586).

**Removed from ResourceManager:**
- `createFungibleToken()`, `createNftToken()`, `createFile()`, `createTopic()`
- `TestFungibleToken`, `TestNftToken`, `TestFile`, `TestTopic`, `AnyTestToken`, `TestTokenProtocol`
- `private var tokens`, `private var files`, `private var topics` storage

**Kept in ResourceManager:**
- `TestAccount`, `TestContract` (used internally for cleanup logic)
- `private var accounts`, `private var contracts` (needed for cleanup)
- `settleTokenBalances`, `deleteAccount`, `deleteContract` (cleanup logic)
- `unpauseTokenIfNeeded` (cleanup logic)

### Service Helper Pattern

Each helper is an extension of `HieroIntegrationTestCase`:

```swift
// HieroIntegrationTestCase+Token.swift
extension HieroIntegrationTestCase {
    
    // MARK: - Token Creation (public - tests call these)
    
    public func createToken(
        _ transaction: TokenCreateTransaction,
        adminKey: PrivateKey? = nil,
        supplyKey: PrivateKey? = nil,
        wipeKey: PrivateKey? = nil,
        pauseKey: PrivateKey? = nil
    ) async throws -> TokenId
    
    public func createUnmanagedToken(_ transaction: TokenCreateTransaction) async throws -> TokenId
    
    // MARK: - Convenience Helpers (public - tests call these)
    
    public func createBasicFungibleToken(...) async throws -> TokenId
    public func createFungibleTokenWithSupplyKey(...) async throws -> (tokenId: TokenId, supplyKey: PrivateKey)
    public func createNftWithSupplyKey(...) async throws -> (tokenId: TokenId, supplyKey: PrivateKey)
    public func associateToken(_ tokenId: TokenId, with accountId: AccountId, key: PrivateKey) async throws
    
    // MARK: - Assertions (public - tests call these)
    
    public func assertTokenInfo(_ info: TokenInfo, tokenId: TokenId, ...) 
    
    // MARK: - Registration (internal - tests never see these)
    
    internal func registerToken(_ tokenId: TokenId, adminKey: PrivateKey, ...) async
}
```

### Helper Contents by File

**HieroIntegrationTestCase+Account.swift:**
- `createAccount(_ transaction, key:)` / `createAccount(_ transaction, keys:)`
- `createUnmanagedAccount(_ transaction)`
- `createTestAccount(initialBalance: Hbar? = nil)` - consolidated from `createTestAccount()` + `createFundedAccount()`
- `createSimpleUnmanagedAccount(initialBalance:)`
- `generateEcdsaKeyWithEvmAddress()`
- `isZeroEvmAddress(_:)`
- `assertAccountInfo(...)`, `assertAccountInfoWithEvmAddress(...)`, `assertAccountInfoContainsEvmAddress(...)`, `assertAccountBalance(...)`
- `registerAccount(...)` (internal)

**HieroIntegrationTestCase+Token.swift:**
- `createToken(_ transaction, adminKey:, supplyKey:, wipeKey:, pauseKey:)`
- `createUnmanagedToken(_ transaction)`
- `createBasicFungibleToken(treasuryAccountId:, treasuryKey:, initialSupply:)`
- `createFungibleTokenWithSupplyKey(treasuryAccountId:, treasuryKey:, initialSupply:)`
- `createNftWithSupplyKey(treasuryAccountId:, treasuryKey:)`
- `associateToken(_ tokenId, with accountId, key:)`
- `assertTokenInfo(_ info, tokenId:, name:, symbol:)`
- `registerToken(...)` (internal)

**HieroIntegrationTestCase+File.swift:**
- `createFile(_ transaction, key:)` / `createFile(_ transaction, keys:)`
- `createUnmanagedFile(_ transaction)`
- `createTestFile(contents:)`
- `assertFileInfo(_ fileId, size:, isDeleted:, hasKeys:)`
- `assertFileContents(_ fileId, equals:)` (String and Data versions)
- `registerFile(...)` (internal)

**HieroIntegrationTestCase+Topic.swift:**
- `createTopic(_ transaction, adminKey:)` / `createTopic(_ transaction, adminKeys:)`
- `createUnmanagedTopic(_ transaction)`
- `createStandardTopic()`
- `createImmutableTopic()`
- `createTopicWithOperatorAdmin()`
- `assertStandardTopicInfo(_ info, topicId:, memo:)`
- `registerTopic(...)` (internal)

**HieroIntegrationTestCase+Schedule.swift:**
- `createSchedule(_ transaction, adminKey:)` / `createSchedule(_ transaction, adminKeys:)`
- `createUnmanagedSchedule(_ transaction)`
- `standardScheduledTransfer(from:, amount:)`
- `standardScheduledTransferWithAdminKey(from:, amount:)`
- `assertScheduleExecuted(_ info)`
- `assertScheduleNotExecuted(_ info)`
- `registerSchedule(...)` (internal)

**HieroIntegrationTestCase+Contract.swift:**
- `createContract(_ transaction, adminKey:)` / `createContract(_ transaction, adminKeys:)`
- `createUnmanagedContract(_ transaction)`
- `createContractBytecodeFile()`
- `standardContractCreateTransaction(fileId:, adminKey:, gas:)`
- `createStandardContract()`
- `createImmutableContract()`
- `createUnmanagedContractWithOperatorAdmin()`
- `standardContractCreateFlow(adminKey:)`
- `assertStandardContractInfo(_ info, contractId:, adminKey:, storage:)`
- `assertImmutableContractInfo(_ info, contractId:, storage:)`
- `registerContract(...)` (internal)

### TestConstants Updates

Move `standardTopicMemo` to `TestConstants.swift`:
```swift
public static let standardTopicMemo = "[e2e::TopicCreateTransaction]"
```

Change token name:
```swift
public static let tokenName = "ffff"  // Was "Test Token"
```

---

## Implementation Plan

Each phase leaves tests in a passing state.

### Phase 1: Create Extensions + Move Methods + Delete Old Helpers

**This is the big atomic phase.** Do all of these together:

1. **Create 6 new extension files** in `HieroTestSupport/Helpers/`:
   - `HieroIntegrationTestCase+Account.swift`
   - `HieroIntegrationTestCase+Token.swift`
   - `HieroIntegrationTestCase+File.swift`
   - `HieroIntegrationTestCase+Topic.swift`
   - `HieroIntegrationTestCase+Schedule.swift`
   - `HieroIntegrationTestCase+Contract.swift`

2. **Move methods FROM `HieroIntegrationTestCase.swift`** to the new extension files:
   - Token methods → `+Token.swift`
   - Account methods → `+Account.swift`
   - File methods → `+File.swift`
   - Topic methods → `+Topic.swift`
   - Schedule methods → `+Schedule.swift`
   - Contract methods → `+Contract.swift`

3. **Move content FROM old helper files** to new extension files:
   - `TokenIntegrationTestHelpers.swift` → `+Token.swift`
   - `AccountIntegrationTestHelpers.swift` → `+Account.swift`
   - `FileIntegrationTestHelpers.swift` → `+File.swift`
   - `TopicIntegrationTestHelpers.swift` → `+Topic.swift`
   - `ScheduleIntegrationTestHelpers.swift` → `+Schedule.swift`
   - `ContractIntegrationTestHelpers.swift` → `+Contract.swift`

4. **Delete old helper files** from `HieroIntegrationTests/`

5. **Change `resourceManager` access** from `public` to `internal` in `HieroIntegrationTestCase.swift`

**Important:** Keep ALL existing helper methods as-is (no consolidation/removal yet). This includes:
- Keep `createAliceAndBobAccounts()` 
- Keep `createFundedAccount()`
- Keep `createTestAccount()`

Result: `HieroIntegrationTestCase.swift` is ~50 lines. All methods moved to extensions.

✅ **COMPLETE** - Tests pass

**Lessons Learned:**
- **Access Control Across Modules:** `internal` methods in `HieroTestSupport` are NOT accessible from `HieroIntegrationTests` because they are separate Swift modules. All helper methods that tests need to call must be `public`, not `internal`. Only registration methods that tests never call directly should be `internal` (but even these ended up needing to be `public` because the service helpers in `HieroTestSupport` can access `resourceManager` which is `internal`).

---

### Phase 2: Consolidate/Remove Helper Methods

1. Consolidate `createTestAccount()` and `createFundedAccount()` into one method:
   ```swift
   public func createTestAccount(initialBalance: Hbar? = nil) async throws -> (accountId: AccountId, key: PrivateKey)
   ```

2. Remove `createAliceAndBobAccounts()`

3. Update affected tests:
   - Tests using `createFundedAccount(initialBalance:)` → use `createTestAccount(initialBalance:)`
   - Tests using `createAliceAndBobAccounts()` → call `createTestAccount()` twice

✅ **COMPLETE** - Tests pass

---

### Phase 3: Clean Up ResourceManager

**Note from Phase 1:** Since the extension files (e.g., `+Token.swift`) are in `HieroTestSupport` (same module as `ResourceManager`), the registration methods (`registerCleanup`, `registerWipeKey`, etc.) can remain `internal`. Only the test-facing helper methods need to be `public`.

1. Remove unused creation methods:
   - `createFungibleToken()`, `createNftToken()`
   - `createFile()`, `createTopic()`

2. Remove unused wrapper types:
   - `TestFungibleToken`, `TestNftToken`, `TestFile`, `TestTopic`
   - `AnyTestToken`, `TestTokenProtocol`

3. Remove unused storage:
   - `private var tokens: [TokenId: AnyTestToken]`
   - `private var files: [FileId: TestFile]`
   - `private var topics: [TopicId: TestTopic]`

4. Keep `TestAccount` and `TestContract` (used internally for cleanup)

5. Keep `CleanupPriority` in `ResourceManager.swift` (no extraction needed)
   - After cleanup, only ~30 lines of helper types remain (`CleanupPriority`, `TestAccount`, `TestContract`)
   - These are tightly coupled to `ResourceManager` and not shared elsewhere
   - Extracting to a separate file would be over-organization for this small scope

Result: ~350 lines (down from 586) - The `settleTokenBalances` method is complex but necessary.

✅ **COMPLETE** - Tests pass

---

### Phase 4: Update TestConstants

1. Move `standardTopicMemo` from `+Topic.swift` to `TestConstants.swift`
   - Update all test references from `Self.standardTopicMemo` to `TestConstants.standardTopicMemo`

2. Change `tokenName` from `"Test Token"` to `"ffff"`

✅ **COMPLETE** - Tests pass

---

### Phase 5: Verify

1. Build all targets
2. Run all integration tests
3. Fix any remaining issues

---

## Summary

| Area | Before | After |
|------|--------|-------|
| ResourceManager.swift | 586 lines | 348 lines |
| HieroIntegrationTestCase.swift | 642 lines | ~35 lines |
| Helper files in HieroIntegrationTests | 6 files | 0 files |
| Helper files in HieroTestSupport | 0 files | 6 files |

**Benefits:**
1. Clean layering: Tests → Helpers → ResourceManager
2. ResourceManager hidden from tests
3. Per-test instance supports parallel execution
4. Single source of truth for helpers
5. Minimal base class
6. No dead code
7. Better discoverability
8. Proper access control (`public` for all test-facing methods since they cross module boundaries)

---

## Execution Log

### Phase 1 - ✅ COMPLETE
**Date:** Dec 5, 2025

**What was done:**
1. Created 6 new extension files in `HieroTestSupport/Helpers/`
2. Moved all methods from `HieroIntegrationTestCase.swift` to appropriate extensions
3. Moved content from old helper files to new extensions
4. Deleted 6 old helper files from `HieroIntegrationTests/`
5. Changed `resourceManager` from `public` to `internal`

**Issues encountered:**
- **Access Control:** Initial implementation marked helper methods as `internal`, which caused build failures because `HieroTestSupport` and `HieroIntegrationTests` are separate Swift modules. Had to change all test-facing helper methods to `public`. Only `resourceManager` property is `internal`.

**Observations (non-blocking):**
- **Registration methods could be `internal`:** Methods like `registerToken()`, `registerAccount()`, etc. were made `public` but could technically remain `internal` since they're only called from within the same `HieroTestSupport` module (e.g., `createToken()` calls `registerToken()` internally). This results in slightly more public API surface than strictly necessary. Could be tightened up in a future cleanup pass if desired.

**Files created:**
- `Tests/HieroTestSupport/Helpers/HieroIntegrationTestCase+Token.swift`
- `Tests/HieroTestSupport/Helpers/HieroIntegrationTestCase+Account.swift`
- `Tests/HieroTestSupport/Helpers/HieroIntegrationTestCase+File.swift`
- `Tests/HieroTestSupport/Helpers/HieroIntegrationTestCase+Topic.swift`
- `Tests/HieroTestSupport/Helpers/HieroIntegrationTestCase+Schedule.swift`
- `Tests/HieroTestSupport/Helpers/HieroIntegrationTestCase+Contract.swift`

**Files deleted:**
- `Tests/HieroIntegrationTests/Token/TokenIntegrationTestHelpers.swift`
- `Tests/HieroIntegrationTests/Account/AccountIntegrationTestHelpers.swift`
- `Tests/HieroIntegrationTests/File/FileIntegrationTestHelpers.swift`
- `Tests/HieroIntegrationTests/Topic/TopicIntegrationTestHelpers.swift`
- `Tests/HieroIntegrationTests/Schedule/ScheduleIntegrationTestHelpers.swift`
- `Tests/HieroIntegrationTests/Contract/ContractIntegrationTestHelpers.swift`

**Files modified:**
- `Tests/HieroTestSupport/Base/HieroIntegrationTestCase.swift` (slimmed to ~35 lines)

**Build status:** ✅ Passing

### Phase 4 - ✅ COMPLETE
**Date:** Dec 5, 2025

**What was done:**
1. Added `standardTopicMemo` to `TestConstants.swift`
2. Removed `standardTopicMemo` from `HieroIntegrationTestCase+Topic.swift`
3. Updated 7 references from `Self.standardTopicMemo` to `TestConstants.standardTopicMemo`
4. Changed `tokenName` from `"Test Token"` to `"ffff"`

**Files modified:**
- `Tests/HieroTestSupport/Fixtures/TestConstants.swift` - added `standardTopicMemo`, changed `tokenName`
- `Tests/HieroTestSupport/Helpers/HieroIntegrationTestCase+Topic.swift` - removed constant, updated references
- `Tests/HieroIntegrationTests/Topic/TopicDeleteTransactionIntegrationTests.swift` - updated reference
- `Tests/HieroIntegrationTests/Topic/TopicCreateTransactionIntegrationTests.swift` - updated reference
- `Tests/HieroIntegrationTests/Topic/TopicInfoQueryIntegrationTests.swift` - updated 3 references

**Build status:** ✅ Passing

### Phase 3 - ✅ COMPLETE
**Date:** Dec 5, 2025

**What was done:**
1. Removed unused creation methods: `createFungibleToken()`, `createNftToken()`, `createFile()`, `createTopic()`
2. Removed unused delete methods: `deleteToken(_:)`, `deleteFile(_:)`, `deleteTopic(_:)`
3. Removed unused wrapper types: `TestFungibleToken`, `TestNftToken`, `TestFile`, `TestTopic`, `AnyTestToken`, `TestTokenProtocol`
4. Removed unused storage: `private var tokens`, `private var files`, `private var topics`
5. Cleaned up `cleanup()` method to remove references to removed storage
6. Changed `TestAccount` and `TestContract` from `public` to `internal` (no `public` keyword)
7. Kept `CleanupPriority` in same file (no extraction needed)

**Results:**
- ResourceManager.swift: 586 lines → 348 lines (40% reduction)
- Removed 6 unused methods, 6 unused types, 3 unused storage properties

**Lessons Learned:**
- **Line count higher than estimated:** The original estimate was 150-200 lines, but the actual result is 348 lines. This is because `settleTokenBalances` is complex (~100 lines) but essential for cleanup - you can remove creation methods but cleanup logic must remain intact.
- **Full rewrite vs incremental edits:** For large-scale removals like this (removing 50%+ of a file), rewriting the entire file is cleaner and less error-prone than many search/replace operations.
- **Internal types can stay in same file:** `TestAccount` and `TestContract` are now internal (no `public` keyword) since they're only used within `ResourceManager`. No need to extract them to a separate file.

**Files modified:**
- `Tests/HieroTestSupport/Helpers/ResourceManager.swift` - major cleanup

**Build status:** ✅ Passing

### Phase 2 - ✅ COMPLETE
**Date:** Dec 5, 2025

**What was done:**
1. Created consolidated `createTestAccount(initialBalance: Hbar? = nil)` in `+Account.swift`
2. Removed `createTestAccount()` and `createAliceAndBobAccounts()` from `+Token.swift`
3. Removed `createFundedAccount()` from `+Account.swift` (replaced by new consolidated function)
4. Updated 11 test usages of `createAliceAndBobAccounts()` to use two `createTestAccount()` calls
5. Updated 11 test usages of `createFundedAccount()` to use `createTestAccount(initialBalance:)`

**Observations:**
- **Default Behavior Change:** The old `createFundedAccount()` defaulted to `TestConstants.testMediumHbarBalance`, but the new `createTestAccount(initialBalance:)` defaults to `nil` (no balance). Tests that previously called `createFundedAccount()` without arguments needed explicit `initialBalance: TestConstants.testMediumHbarBalance` to maintain the same behavior.

**Files modified:**
- `Tests/HieroTestSupport/Helpers/HieroIntegrationTestCase+Account.swift` - new consolidated method
- `Tests/HieroTestSupport/Helpers/HieroIntegrationTestCase+Token.swift` - removed old methods
- `Tests/HieroIntegrationTests/Token/TokenNftTransferIntegrationTests.swift`
- `Tests/HieroIntegrationTests/Token/TokenWipeTransactionIntegrationTests.swift`
- `Tests/HieroIntegrationTests/Token/TokenBurnTransactionIntegrationTests.swift`
- `Tests/HieroIntegrationTests/Token/TokenTransferIntegrationTests.swift`
- `Tests/HieroIntegrationTests/Schedule/ScheduleCreateTransactionIntegrationTests.swift`
- `Tests/HieroIntegrationTests/Schedule/ScheduleInfoQueryIntegrationTests.swift`
- `Tests/HieroIntegrationTests/Schedule/ScheduleDeleteTransactionIntegrationTests.swift`
- `Tests/HieroIntegrationTests/Account/AccountAllowanceApproveTransactionIntegrationTests.swift`

**Build status:** ✅ Passing
