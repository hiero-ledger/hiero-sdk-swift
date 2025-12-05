# HieroTestSupport Audit Report

**Last Updated**: Post-Cleanup Audit  
**Files**: 27 Swift files across 6 directories  
**Status**: ✅ Cleanup complete

---

## Executive Summary

The `HieroTestSupport` target successfully provides shared test infrastructure for both unit and integration tests. After the recent migration:

- ✅ All 126+ unit tests now extend `HieroUnitTestCase`
- ✅ `TransactionTestable` and `QueryTestable` protocols adopted (47+ and 13+ files respectively)
- ✅ `TestConstants` is the single source of truth for test fixtures
- ✅ `Resources.swift` removed from HieroUnitTests (consolidated into TestConstants)

**Completed**: Removed ~350 lines of dead code and 2 files.

---

## Current Directory Structure (Post-Cleanup)

```
HieroTestSupport/
├── Assertions/
│   └── HieroAssertions.swift         # ✅ Single function: assertThrowsHErrorAsync
├── Base/
│   ├── HieroTestCase.swift           # ✅ Base for all tests
│   ├── HieroUnitTestCase.swift       # ✅ Re-exports + base class
│   └── HieroIntegrationTestCase.swift # ✅ Used by all integration tests
├── Environment/                       # ✅ All files in use
│   ├── CleanupPolicy.swift
│   ├── DotenvLoader.swift
│   ├── EnvironmentValidation.swift
│   ├── EnvironmentVariables.swift
│   ├── FeatureFlags.swift
│   ├── IntegrationTestEnvironment.swift
│   ├── NetworkConfig.swift
│   ├── OperatorConfig.swift
│   ├── TestDefaults.swift
│   ├── TestEnvironmentConfig.swift
│   ├── TestEnvironmentType.swift
│   └── TestProfile.swift
├── Extensions/
│   └── Transaction+Testing.swift     # ✅ In use (makeProtoBody)
├── Fixtures/
│   └── TestConstants.swift           # ✅ All test constants + bytecode
├── Helpers/                          # ✅ All files in use
│   ├── HieroIntegrationTestCase+Account.swift
│   ├── HieroIntegrationTestCase+Contract.swift
│   ├── HieroIntegrationTestCase+File.swift
│   ├── HieroIntegrationTestCase+Schedule.swift
│   ├── HieroIntegrationTestCase+Token.swift
│   ├── HieroIntegrationTestCase+Topic.swift
│   └── ResourceManager.swift
└── Protocols/                        # ✅ All files in use
    ├── TransactionTestable.swift
    └── QueryTestable.swift
```

---

## Usage Statistics

### Heavily Used Components

| Component | Usage Count | Status |
|-----------|-------------|--------|
| `HieroUnitTestCase` | 126 files | ✅ Base class for unit tests |
| `HieroIntegrationTestCase` | 65 files | ✅ Base class for integration tests |
| `TestConstants.*` | 398 matches | ✅ Single source of truth |
| `TransactionTestable` | 47 files | ✅ Protocol for tx tests |
| `QueryTestable` | 13 files | ✅ Protocol for query tests |
| `assertThrowsHErrorAsync` | 212 matches | ✅ Primary error assertion |
| `makeProtoBody()` | 100+ uses | ✅ Transaction serialization |

### Lightly Used Components

| Component | Usage Count | Notes |
|-----------|-------------|-------|
| `TestResources.shared.contractBytecode` | 2 uses | Move to TestConstants |

### Dead Code ✅ REMOVED

All dead code has been removed:
- Deleted `XCTestCase+Hiero.swift` (79 lines)
- Cleaned `HieroAssertions.swift` (removed 197 lines)
- Cleaned `HieroUnitTestCase.swift` (removed 34 lines)  
- Deleted `TestResources.swift` (60 lines, moved `contractBytecode` to TestConstants)

**Total Removed**: ~370 lines

---

## Proposed Changes

### 1. DELETE `XCTestCase+Hiero.swift` (79 lines)

**Reason**: All functions are either unused or duplicated elsewhere.

- `assertThrowsHErrorAsync` duplicates `HieroAssertions.swift`
- `skipUnless`, `skipIf`, `measureAsync`, `assertCompletesWithin` have 0 uses

```bash
rm Tests/HieroTestSupport/Extensions/XCTestCase+Hiero.swift
```

---

### 2. CLEAN UP `HieroAssertions.swift` (249 → 34 lines)

**Keep only**:
- `assertThrowsHErrorAsync` (used 212 times by integration tests)

**Delete**:
- All `assertTransaction*` functions (0 uses)
- All `assert*Created` functions (0 uses)  
- All `assert*Exists` functions (0 uses)
- Both `assertAccountBalance` overloads (0 uses)

**After cleanup**:

```swift
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

/// Assert that an async expression throws an HError
///
/// - Parameters:
///   - expression: The async expression to evaluate
///   - message: Optional message on failure
///   - file: Source file (auto-captured)
///   - line: Source line (auto-captured)
///   - errorHandler: Closure to inspect the error
public func assertThrowsHErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line,
    _ errorHandler: (_ error: HError) -> Void = { _ in }
) async {
    do {
        _ = try await expression()

        let message = message()
        var compactDescription: String = "assertThrowsHErrorAsync failed: did not throw an error"

        if !message.isEmpty {
            compactDescription += " - \(message)"
        }

        XCTFail(compactDescription, file: file, line: line)

    } catch let error as HError {
        errorHandler(error)
    } catch {
        XCTFail("assertThrowsHErrorAsync failed: did not throw a HError: \(error)", file: file, line: line)
    }
}
```

---

### 3. CLEAN UP `HieroUnitTestCase.swift` (110 → 50 lines)

**Delete** unused methods:
- `assertProtoEquivalent` (0 uses)
- `assertSerializationRoundTrip` (0 uses)
- `assertProtoBodyRoundTrip` (0 uses)

**Keep**:
- Re-exports (`@_exported import SnapshotTesting`, `@_exported import HieroProtobufs`)
- Class definition and `setUp()`

**After cleanup**:

```swift
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroProtobufs
import SnapshotTesting
import XCTest

// MARK: - Re-exports for convenience

// Re-export SnapshotTesting so tests only need to import HieroTestSupport
@_exported import SnapshotTesting

// Re-export HieroProtobufs for protobuf types in tests
@_exported import HieroProtobufs

/// Base class for unit tests (no network required)
///
/// Provides common utilities for unit testing Hiero SDK types.
/// For transaction tests, combine with `TransactionTestable` protocol.
/// For query tests, combine with `QueryTestable` protocol.
///
/// ## Usage
/// ```swift
/// import HieroTestSupport
/// @testable import Hiero
///
/// internal final class MyTransactionTests: HieroUnitTestCase, TransactionTestable {
///     typealias TransactionType = MyTransaction
///
///     static func makeTransaction() throws -> MyTransaction {
///         // ... create transaction
///     }
///
///     func test_Serialize() throws {
///         try assertTransactionSerializes()
///     }
///
///     func test_ToFromBytes() throws {
///         try assertTransactionRoundTrips()
///     }
/// }
/// ```
open class HieroUnitTestCase: HieroTestCase {

    open override func setUp() async throws {
        try await super.setUp()
    }
}
```

---

### 4. DELETE `TestResources.swift` (60 lines)

**First**: Move `contractBytecode` to `TestConstants.swift`.

**Add to TestConstants.swift**:

```swift
// MARK: - Contract Bytecode

/// Standard contract bytecode for testing (stateful contract with getMessage/setMessage)
public static let contractBytecode: Data = {
    let bytecodeString = """
        608060405234801561001057600080fd5b506040516104d73803806104d7833981810160405260208110156100\
        3357600080fd5b810190808051604051939291908464010000000082111561005357600080fd5b908301906020\
        ... (rest of bytecode)
        """
    return bytecodeString.data(using: .utf8)!
}()
```

**Then**: Delete `TestResources.swift`.

**Update** `HieroIntegrationTestCase+Contract.swift` to use `TestConstants.contractBytecode` instead of `TestResources.shared.contractBytecode`.

```bash
rm Tests/HieroTestSupport/Fixtures/TestResources.swift
```

---

## Implementation Checklist

### Phase 1: Remove Dead Files ✅
- [x] Delete `Extensions/XCTestCase+Hiero.swift`

### Phase 2: Clean Up HieroAssertions.swift ✅
- [x] Remove all unused assertion functions
- [x] Keep only `assertThrowsHErrorAsync`
- [x] Reduced from 249 → 52 lines

### Phase 3: Clean Up HieroUnitTestCase.swift ✅
- [x] Remove `assertProtoEquivalent`
- [x] Remove `assertSerializationRoundTrip`
- [x] Remove `assertProtoBodyRoundTrip`
- [x] Improved documentation
- [x] Reduced from 110 → 76 lines

### Phase 4: Consolidate TestResources ✅
- [x] Add `contractBytecode` to `TestConstants.swift`
- [x] Update `HieroIntegrationTestCase+Contract.swift` (2 locations)
- [x] Delete `TestResources.swift`

### Phase 5: Verify
- [ ] Run unit tests: `swift test --filter HieroUnitTests`
- [ ] Run integration tests: `swift test --filter HieroIntegrationTests`

---

## Summary of Impact

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Files | 29 | 27 | -2 |
| Lines of Code | ~2,500 | ~2,150 | -350 |
| Dead Code | ~350 lines | 0 | -100% |
| Public API Surface | ~65 functions | ~15 functions | -77% |

---

## Architecture Notes

### Test Base Class Hierarchy

```
XCTestCase
    └── HieroTestCase (loads environment config)
            ├── HieroUnitTestCase (re-exports, protocols)
            │       ├── + TransactionTestable (optional)
            │       └── + QueryTestable (optional)
            └── HieroIntegrationTestCase (network, cleanup)
```

### Re-Export Strategy

`HieroUnitTestCase` uses `@_exported import` so test files only need:

```swift
import HieroTestSupport
@testable import Hiero
```

This automatically provides:
- `SnapshotTesting.assertSnapshot`
- All `HieroProtobufs` types (Proto_*)
- All test constants and protocols

### Protocol Design

**TransactionTestable**:
- Requires: `associatedtype TransactionType`, `static func makeTransaction()`
- Provides: `assertTransactionSerializes()`, `assertTransactionRoundTrips()`

**QueryTestable**:
- Requires: `static func makeQueryProto() -> Proto_Query`
- Provides: `assertQuerySerializes()`

Both protocols use explicit `SnapshotTesting.assertSnapshot()` to avoid ambiguity.
