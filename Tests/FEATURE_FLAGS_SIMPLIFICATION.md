# Feature Flags Simplification

## Summary

Removed two redundant feature flags (`networkRequired` and `enableSnapshots`) that were attempting to control behavior already determined by test architecture.

## Before and After

### Before: 6 Flags
```swift
public struct FeatureFlags {
    public var networkRequired: Bool        // ❌ Removed
    public var enableSnapshots: Bool        // ❌ Removed
    public var maxTestDuration: TimeInterval
    public var parallelExecution: Bool
    public var verboseLogging: Bool
    public var cleanupPolicy: CleanupPolicy
}
```

### After: 4 Flags
```swift
public struct FeatureFlags {
    public var maxTestDuration: TimeInterval
    public var parallelExecution: Bool
    public var verboseLogging: Bool
    public var cleanupPolicy: CleanupPolicy
}
```

## Why These Flags Were Redundant

### `networkRequired` - Structural Redundancy

**Problem:** Base class already determines network requirements

```swift
// Unit tests - never need network
class MyTest: HieroUnitTestCase { }

// Integration tests - always need network
class MyTest: HieroIntegrationTestCase { }
```

The flag couldn't change this fundamental architecture.

### `enableSnapshots` - Dangerous False Positives

**Problem:** Allowed tests to pass without actually checking anything

```swift
// With flag disabled:
assertSnapshot(of: transaction)  // Returns early, test passes!
```

**Better:** Use the snapshot library's built-in recording mode.

## What Determines Test Behavior Now

### Network Requirements
**Determined by:** Base class choice
- `HieroUnitTestCase` → No network
- `HieroIntegrationTestCase` → Requires network (skips if no operator)

### Snapshot Checking  
**Determined by:** Calling `assertSnapshot()` or not
- If you call it → Always checks
- If you don't call it → No checking
- For recording → Use `SNAPSHOT_RECORD=1`

### Still Configurable via Flags
- ✅ `maxTestDuration` - Real runtime constraint
- ✅ `parallelExecution` - Real execution strategy  
- ✅ `verboseLogging` - Real debugging toggle
- ✅ `cleanupPolicy` - Real resource management choice

## Simplified Profile Definitions

### Before (6 parameters)
```swift
public static var ciUnit: Self {
    FeatureFlags(
        networkRequired: false,      // ❌ Redundant
        enableSnapshots: true,       // ❌ Redundant
        maxTestDuration: 120,
        parallelExecution: false,
        verboseLogging: true,
        cleanupPolicy: .none
    )
}
```

### After (4 parameters)
```swift
public static var ciUnit: Self {
    FeatureFlags(
        maxTestDuration: 120,
        parallelExecution: false,
        verboseLogging: true,
        cleanupPolicy: .none
    )
}
```

## All Profiles Updated

| Profile | Purpose | Duration | Parallel | Verbose | Cleanup |
|---------|---------|----------|----------|---------|---------|
| `local` | Dev (unit + integration) | 300s | ✓ true | ✗ false | economical |
| `ciUnit` | CI unit tests | 120s | ✗ false | ✓ true | none |
| `ciIntegration` | CI integration tests | 600s | ✗ false | ✓ true | none |
| `development` | Dev integration tests | 300s | ✓ true | ✓ true | economical |

**Note:** No more `networkRequired` or `enableSnapshots` columns!

## Environment Variables Removed

- ❌ `TEST_NETWORK_REQUIRED`
- ❌ `TEST_ENABLE_SNAPSHOTS`

## Benefits

✅ **Simpler API** - Fewer parameters to understand  
✅ **Less confusion** - Flags match actual runtime controls  
✅ **No redundancy** - Base class determines structure  
✅ **Safer tests** - No silent skipping of assertions  
✅ **Clearer intent** - Test class name shows requirements  

## Files Changed

- `Tests/HieroTestSupport/Environment/FeatureFlags.swift`
- `Tests/HieroTestSupport/Environment/TestDefaults.swift`
- `Tests/HieroTestSupport/Environment/EnvironmentVariables.swift`
- `Tests/HieroTestSupport/Environment/EnvironmentValidation.swift`
- `Tests/HieroTestSupport/Environment/DotenvLoader.swift`
- `Tests/HieroTestSupport/Base/HieroUnitTestCase.swift`

## Related Documentation

- `NETWORK_REQUIRED_REMOVAL.md` - Detailed rationale for removing `networkRequired`
- `ENABLE_SNAPSHOTS_REMOVAL.md` - Detailed rationale for removing `enableSnapshots`

