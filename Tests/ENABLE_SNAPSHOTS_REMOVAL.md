# Removal of `enableSnapshots` Flag

## Summary

The `enableSnapshots` feature flag has been removed. Snapshot assertions in unit tests now always check snapshots when called.

## Rationale

### The Problem

The `enableSnapshots` flag allowed snapshot checking to be disabled:

```swift
// OLD: Could silently skip snapshot verification
public func assertSnapshot<T>(...) {
    guard config.features.enableSnapshots else {
        return  // ⚠️ Test passes without checking anything!
    }
    SnapshotTesting.assertSnapshot(...)
}
```

**This created dangerous scenarios:**
- Tests appear to pass but aren't verifying correctness
- False positives in CI
- Confusion about what's actually being tested

### The Correct Pattern

**Snapshot recording is handled by the snapshot library itself:**

```bash
# swift-snapshot-testing has its own recording mode
SNAPSHOT_RECORD=1 swift test

# Or programmatically
record = true  // in the test
```

You don't need a custom flag for this - the library already provides it!

### Integration Tests Don't Use Snapshots Anyway

`HieroIntegrationTestCase` doesn't have `assertSnapshot()` method, so:
- Integration tests never call snapshot assertions
- The flag was only checked in `HieroUnitTestCase`
- Having it in profiles for integration tests (`ciIntegration`, `development`) was redundant

## What Was Removed

### 1. FeatureFlags

**Before:**
```swift
public struct FeatureFlags {
    public var enableSnapshots: Bool
    public var maxTestDuration: TimeInterval
    // ...
}
```

**After:**
```swift
public struct FeatureFlags {
    public var maxTestDuration: TimeInterval
    // ...
}
```

### 2. Environment Variable

- ❌ Removed `TEST_ENABLE_SNAPSHOTS` environment variable
- ❌ Removed from `DotenvLoader`
- ❌ Removed from `EnvironmentVariables.swift`
- ❌ Removed from `EnvironmentValidation.swift` documentation

### 3. TestDefaults

**Before:**
```swift
public static let enableSnapshots: Bool = true
```

**After:**
```swift
// Removed - not needed
```

### 4. Profile Definitions

All profiles simplified:

**Before:**
```swift
public static var ciUnit: Self {
    FeatureFlags(
        enableSnapshots: true,  // ❌ Redundant with library's recording mode
        maxTestDuration: 120,
        // ...
    )
}
```

**After:**
```swift
public static var ciUnit: Self {
    FeatureFlags(
        maxTestDuration: 120,
        // ...
    )
}
```

### 5. HieroUnitTestCase

**Before:**
```swift
public func assertSnapshot<T>(...) {
    guard config.features.enableSnapshots else {
        return  // Silently skip
    }
    
    SnapshotTesting.assertSnapshot(...)
}
```

**After:**
```swift
public func assertSnapshot<T>(...) {
    SnapshotTesting.assertSnapshot(...)
}
```

## How Snapshot Testing Works Now

### Always Verify by Default

```swift
class MyUnitTest: HieroUnitTestCase {
    func testTransaction() {
        let tx = AccountCreateTransaction()
        
        // ✅ Always checks snapshot
        assertSnapshot(of: tx)
    }
}
```

### Recording New Snapshots

Use the snapshot testing library's built-in recording mode:

```bash
# Record/update snapshots
SNAPSHOT_RECORD=1 swift test --filter HieroUnitTests

# Verify snapshots (normal run)
swift test --filter HieroUnitTests
```

Or programmatically in a test file:
```swift
import SnapshotTesting

class MyTests: HieroUnitTestCase {
    override func setUp() async throws {
        try await super.setUp()
        // record = true  // Uncomment to record
    }
}
```

### Integration Tests

Integration tests don't use snapshots:
- They verify behavior via real network calls
- No `assertSnapshot()` method available
- Nothing to configure

## Benefits

✅ **Safer tests** - Assertions always verify correctness  
✅ **Less confusion** - No silent skipping of checks  
✅ **Standard practice** - Use library's recording mode like everyone else  
✅ **Simpler configuration** - One less flag to manage  
✅ **No false positives** - Can't accidentally pass tests that aren't checking anything  

## Migration

**No migration needed!** If your tests were using `assertSnapshot()`, they now always check snapshots (as they should).

**If you were temporarily disabling snapshots:**
- **For recording**: Use `SNAPSHOT_RECORD=1` instead
- **For development**: Comment out the `assertSnapshot()` call or use `record = true`

## Related Files Changed

- `Tests/HieroTestSupport/Environment/FeatureFlags.swift`
- `Tests/HieroTestSupport/Environment/TestDefaults.swift`
- `Tests/HieroTestSupport/Environment/EnvironmentVariables.swift`
- `Tests/HieroTestSupport/Environment/EnvironmentValidation.swift`
- `Tests/HieroTestSupport/Environment/DotenvLoader.swift`
- `Tests/HieroTestSupport/Base/HieroUnitTestCase.swift`

All profile definitions (`local`, `ciUnit`, `ciIntegration`, `development`) updated to remove `enableSnapshots` parameter.

