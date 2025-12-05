# Snapshot Testing Configuration

## Overview

Fixed snapshot testing configuration to only be enabled for profiles that actually run unit tests. Snapshots are a unit testing feature (used for protobuf serialization testing) and have no purpose in integration-only tests.

## What Are Snapshots?

Snapshot testing (via `SnapshotTesting` library) is used in `HieroUnitTestCase` to verify:
- Protobuf serialization correctness
- Transaction structure consistency
- Complex data structure outputs

**Only used in:** `HieroUnitTestCase` (not in `HieroIntegrationTestCase`)

## Fixed Configuration

### Before (Incorrect)

Snapshots were enabled for almost all profiles, even integration-only ones:

```swift
ciIntegration: enableSnapshots: true  // ❌ Wrong - no unit tests
development: enableSnapshots: true    // ❌ Wrong - integration only
```

### After (Correct)

Snapshots now align with test types:

| Profile | Snapshots? | Reason |
|---------|------------|--------|
| `quickLocal` | ❌ No | Disabled for speed (unit tests, but quick iteration) |
| `fullLocal` | ✅ Yes | Includes unit tests |
| `ciUnit` | ✅ Yes | Unit tests only - primary use case for snapshots |
| `ciIntegration` | ❌ No | Integration tests only - no snapshots needed |
| `development` | ❌ No | Integration tests only - no snapshots needed |

## Rationale

### Why Integration Tests Don't Need Snapshots

**Integration tests** verify real network behavior:
- Submitting transactions to actual nodes
- Querying actual state
- Testing consensus and execution
- **No protobuf serialization testing needed**

**Unit tests** verify code correctness in isolation:
- Transaction serialization/deserialization
- Protobuf structure
- Business logic without network
- **Snapshots are perfect for this**

### Profile-Specific Reasoning

**`quickLocal`** (unit tests):
- Snapshots **disabled** for speed
- Quick iteration during development
- Can enable with `TEST_ENABLE_SNAPSHOTS=1` if needed

**`fullLocal`** (unit + integration):
- Snapshots **enabled** because it runs unit tests
- Complete testing including protobuf verification

**`ciUnit`** (unit tests only):
- Snapshots **enabled** - this is the primary use case
- CI should verify snapshot consistency

**`ciIntegration`** (integration only):
- Snapshots **disabled** - not applicable
- Tests real network behavior only

**`development`** (integration only):
- Snapshots **disabled** - not applicable
- Running against testnet/custom environments

## Usage

### Unit Tests with Snapshots

```swift
final class MyTransactionUnitTests: HieroUnitTestCase {
    func testProtoSerialization() throws {
        let transaction = AccountCreateTransaction()
            .keyWithoutAlias(.single(testKeys.publicKey))
            .initialBalance(Hbar(10))
        
        // Uses snapshot testing (only if enableSnapshots is true)
        assertSnapshot(matching: transaction.makeProtoBody())
    }
}
```

### Integration Tests (No Snapshots)

```swift
final class AccountCreateIntegrationTests: HieroIntegrationTestCase {
    func testCreateAccount() async throws {
        // Tests real network behavior
        let account = try await createAccount(balance: Hbar(10))
        
        // Verify against actual network state
        let info = try await AccountInfoQuery()
            .accountId(account.id)
            .execute(testEnv.client)
        
        XCTAssertEqual(info.balance, Hbar(10))
        // No snapshots needed - testing real behavior
    }
}
```

## Environment Variable Override

You can still override per environment if needed:

```bash
# Force snapshots on (e.g., for unit tests in development profile)
TEST_ENABLE_SNAPSHOTS=1

# Force snapshots off (e.g., for ciUnit if snapshot files are problematic)
TEST_ENABLE_SNAPSHOTS=0
```

## Technical Details

### How Snapshots Are Checked

In `HieroUnitTestCase.swift`:

```swift
public func assertSnapshot<T>(
    matching value: T,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    guard config.features.enableSnapshots else {
        return  // Silently skip if snapshots disabled
    }
    
    SnapshotTesting.assertSnapshot(of: value, /* ... */)
}
```

### Snapshot Storage

Snapshots are stored in `__Snapshots__` directories:
- `Tests/HieroTests/__Snapshots__/` - Unit test snapshots
- Excluded from version control in some cases
- Should be committed for CI verification

## Benefits

### Clarity
- Clear which profiles use snapshots and why
- No confusion about integration test capabilities

### Performance
- Integration tests don't waste time checking snapshot config
- Faster test execution for integration-only profiles

### Correctness
- Snapshots only enabled where they're actually used
- Prevents misleading configuration

## Summary

**Key Change:**
- Integration-only profiles (`ciIntegration`, `development`) now have `enableSnapshots: false`
- Unit test profiles (`ciUnit`, `fullLocal`) keep `enableSnapshots: true`
- Quick iteration profile (`quickLocal`) has it disabled for speed

**Result:**
- ✅ Configuration now matches actual usage
- ✅ No misleading flags in integration test profiles
- ✅ Can still override via `TEST_ENABLE_SNAPSHOTS` if needed
- ✅ Build passes

