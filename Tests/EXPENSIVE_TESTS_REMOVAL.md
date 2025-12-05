# Expensive Tests Removal Summary

## Overview

Removed the concept of "expensive" tests from the testing framework. The simplified mental model is now:

- **Unit Tests** = No HBAR cost, no network required
- **Integration Tests** = Cost HBAR, use network

All integration tests inherently cost HBAR, so the "expensive" designation was redundant.

## Files Modified

### Code Changes

1. **`Tests/HieroTestSupport/Environment/FeatureFlags.swift`**
   - Removed `runExpensiveTests` property
   - Removed `TEST_RUN_EXPENSIVE` environment variable support
   - Updated all predefined flag configurations (quickLocal, ci, full)

2. **`Tests/HieroTestSupport/Environment/TestProfile.swift`**
   - Removed `runExpensiveTests` from all profile feature flags
   - Simplified profile configurations

3. **`Tests/HieroTestSupport/Environment/TestEnvironmentConfig.swift`**
   - Removed `skipExpensiveTests()` builder method

4. **`Tests/HieroTestSupport/Base/HieroIntegrationTestCase.swift`**
   - Removed `requireExpensiveTests()` method
   - Kept `requireSlowTests()` for tests that take a long time to run (but not necessarily more expensive)

### Documentation Updates

5. **`Tests/README.md`**
   - Removed `TEST_RUN_EXPENSIVE` environment variable documentation
   - Updated test profiles table to remove "Expensive Tests" column
   - Changed example from `testExpensiveOperation()` to `testLongRunningOperation()`
   - Changed best practice from "Manage Costs" to "Be Mindful of Costs"
   - Updated all code examples to use `requireSlowTests()` instead of `requireExpensiveTests()`

6. **`Tests/CONFIGURATION_GUIDE.md`**
   - Removed `TEST_RUN_EXPENSIVE` from environment variables table
   - Removed `TEST_RUN_EXPENSIVE=1` from CI configuration examples
   - Updated cost tracking examples to be simpler

7. **`Tests/MIGRATION_SUMMARY.md`**
   - Updated feature flags description to remove mention of expensive tests
   - Changed FAQ from "skip expensive integration tests" to "skip slow integration tests"

## Simplified Test Categorization

### Before
```
- Unit Tests (no cost, fast)
- Integration Tests (cost HBAR)
  - Regular (some cost)
  - Expensive (high cost) ← redundant category
```

### After
```
- Unit Tests (no cost, fast)
- Integration Tests (cost HBAR)
  - Some may be slow (use requireSlowTests() for long-running tests)
```

## Migration Guide

If you have existing test code that uses:

### Replace `requireExpensiveTests()` with `requireSlowTests()`

```swift
// Before
func testManyAccounts() async throws {
    try requireExpensiveTests()
    // Test that creates many accounts
}

// After
func testManyAccounts() async throws {
    try requireSlowTests()  // If it's actually slow
    // OR just remove the check entirely
}
```

### Remove `TEST_RUN_EXPENSIVE` from .env files

```bash
# Before
TEST_RUN_EXPENSIVE=1

# After
# (just remove this line)
```

### Update Custom Configuration Code

```swift
// Before
let config = TestEnvironmentConfig.builder()
    .skipExpensiveTests()
    .build()

// After
let config = TestEnvironmentConfig.builder()
    .build()
```

## Reasoning

The distinction between "regular" and "expensive" integration tests was artificial. All integration tests:

1. **Cost HBAR** - Some operations cost more than others, but that's inherent to what they're testing
2. **Use the network** - All subject to similar latency and reliability considerations
3. **Should be written efficiently** - Good test design is always important

The `requireSlowTests()` method remains for tests that take a long time to execute (e.g., waiting for consensus, creating many resources), which is a more meaningful distinction for test execution than monetary cost.

## Result

- Simpler mental model
- Less configuration required
- More straightforward test categorization
- Build successfully completes: ✅

No breaking changes for existing tests that don't use the expensive test APIs.

