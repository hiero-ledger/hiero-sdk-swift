# Removal of `networkRequired` Flag

## Summary

The `networkRequired` feature flag has been removed as it was redundant with the existing test base class architecture.

## Rationale

### The Redundancy

**Test class inheritance already determines network requirements:**

1. **`HieroUnitTestCase`** - For unit tests that don't require network
   - No client creation
   - No operator required
   - Can run offline

2. **`HieroIntegrationTestCase`** - For integration tests that require network
   - Creates a client
   - Requires operator credentials
   - Throws `XCTSkip` if operator not provided

### The Problem

The `networkRequired` flag was attempting to control something already controlled by test architecture:

```swift
// OLD: Redundant check in HieroUnitTestCase
if config.type.requiresNetwork && !config.features.networkRequired {
    throw XCTSkip("Skipping network-dependent test in unit test mode")
}
```

**Why this was confusing:**
- If you inherit from `HieroUnitTestCase`, you're already indicating no network needed
- If you inherit from `HieroIntegrationTestCase`, you're already indicating network is needed
- The flag couldn't make a unit test suddenly need a network, or vice versa

### Profile Redundancy

Test profiles also showed this redundancy:

| Profile | Base Class Filter | `networkRequired` (old) |
|---------|------------------|------------------------|
| `ciUnit` | Runs `HieroUnitTests` | `false` |
| `ciIntegration` | Runs `HieroIntegrationTests` | `true` |
| `local` | Both | `true` |

The base class already determined network requirements!

## What Was Removed

### 1. FeatureFlags

**Before:**
```swift
public struct FeatureFlags {
    public var networkRequired: Bool
    public var enableSnapshots: Bool
    // ...
}
```

**After:**
```swift
public struct FeatureFlags {
    public var enableSnapshots: Bool
    // ...
}
```

### 2. Environment Variable

- ❌ Removed `TEST_NETWORK_REQUIRED` environment variable
- ❌ Removed from `DotenvLoader` (if it was there)
- ❌ Removed from `EnvironmentVariables.swift`
- ❌ Removed from `EnvironmentValidation.swift` documentation

### 3. TestDefaults

**Before:**
```swift
public static let networkRequired: Bool = true
```

**After:**
```swift
// Removed - not needed
```

### 4. Profile Definitions

All profile definitions simplified:

**Before:**
```swift
public static var ciUnit: Self {
    FeatureFlags(
        networkRequired: false,  // ❌ Redundant
        enableSnapshots: true,
        // ...
    )
}
```

**After:**
```swift
public static var ciUnit: Self {
    FeatureFlags(
        enableSnapshots: true,
        // ...
    )
}
```

### 5. HieroUnitTestCase

**Before:**
```swift
open override func setUp() async throws {
    try await super.setUp()
    
    // Skip if environment requires network
    if config.type.requiresNetwork && !config.features.networkRequired {
        throw XCTSkip("Skipping network-dependent test in unit test mode")
    }
    
    testKeys = TestKeys.shared
    testConstants = TestConstants.shared
}
```

**After:**
```swift
open override func setUp() async throws {
    try await super.setUp()
    
    testKeys = TestKeys.shared
    testConstants = TestConstants.shared
}
```

## How Network Requirements Work Now

### Clear and Simple Architecture

**Unit Tests:**
```swift
class MyUnitTest: HieroUnitTestCase {
    // ✅ Inheriting from HieroUnitTestCase = no network required
    // ✅ No client created
    // ✅ Can run offline
}
```

**Integration Tests:**
```swift
class MyIntegrationTest: HieroIntegrationTestCase {
    // ✅ Inheriting from HieroIntegrationTestCase = network required
    // ✅ Client created automatically
    // ✅ Skips if no operator credentials
}
```

### Test Filtering

Control which tests run using Xcode test filters, not configuration flags:

```bash
# Run only unit tests
swift test --filter HieroUnitTests

# Run only integration tests  
swift test --filter HieroIntegrationTests

# Run both
swift test
```

## Benefits

✅ **Simpler architecture** - One less flag to configure  
✅ **Less confusion** - Base class clearly indicates requirements  
✅ **No redundancy** - Don't specify the same thing twice  
✅ **Explicit intent** - Test class name shows what it needs  
✅ **Fewer edge cases** - Can't have conflicting settings  

## Migration

**No migration needed!** This was an internal refactoring. Tests continue to work exactly as before:

- Unit tests run without network (via `HieroUnitTestCase`)
- Integration tests require network (via `HieroIntegrationTestCase`)
- Test profiles control other settings (snapshots, timeouts, cleanup, etc.)

## Related Files Changed

- `Tests/HieroTestSupport/Environment/FeatureFlags.swift`
- `Tests/HieroTestSupport/Environment/TestDefaults.swift`
- `Tests/HieroTestSupport/Environment/EnvironmentVariables.swift`
- `Tests/HieroTestSupport/Environment/EnvironmentValidation.swift`
- `Tests/HieroTestSupport/Base/HieroUnitTestCase.swift`

All profile definitions (`local`, `ciUnit`, `ciIntegration`, `development`) updated to remove `networkRequired` parameter.

