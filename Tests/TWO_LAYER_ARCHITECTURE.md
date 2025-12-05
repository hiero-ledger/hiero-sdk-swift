# Two-Layer Environment Configuration Architecture

## Overview

Environment configuration now uses a clean two-layer architecture where defaults are applied at the **first layer** (environment variable reading) rather than scattered throughout config structs.

## The Two Layers

### Layer 1: `EnvironmentVariables` - "What values should be used?"

**Responsibility:** Read environment variables and apply defaults

**Returns:** Non-optional, ready-to-use values

**Example:**
```swift
public struct EnvironmentVariables {
    public struct Defaults {
        public static let networkRequired: Bool = true
        public static let maxTestDuration: TimeInterval = 300
        public static let profile: String = "local"
        // ... all defaults in one place
    }
    
    /// Returns whether network is required, or default if not set
    public static var networkRequired: Bool {
        guard let value = env["TEST_NETWORK_REQUIRED"] else {
            return Defaults.networkRequired
        }
        return value == "1"
    }
    
    /// Returns max test duration, or default if not set
    public static var maxTestDuration: TimeInterval {
        guard let durationStr = env["TEST_MAX_DURATION"],
              let duration = TimeInterval(durationStr)
        else {
            return Defaults.maxTestDuration
        }
        return duration
    }
}
```

### Layer 2: Config Structs - "How should values be structured?"

**Responsibility:** Organize values into logical structures

**Consumes:** Ready-to-use values from Layer 1 (no nil coalescing needed)

**Example:**
```swift
public struct FeatureFlags {
    public var networkRequired: Bool
    public var maxTestDuration: TimeInterval
    // ...
    
    /// Load feature flags from environment variables
    /// Defaults are applied at the EnvironmentVariables layer
    public static func fromEnvironment() -> Self {
        FeatureFlags(
            networkRequired: EnvironmentVariables.networkRequired,  // Just use it!
            maxTestDuration: EnvironmentVariables.maxTestDuration,  // No ?? needed
            // ...
        )
    }
}
```

## Before vs After

### Before: Scattered Defaults

```swift
// Layer 1: EnvironmentVariables.swift
public static var maxTestDuration: TimeInterval? {  // Optional
    guard let str = env["TEST_MAX_DURATION"],
          let duration = TimeInterval(str) else {
        return nil  // No default here
    }
    return duration
}

// Layer 2: FeatureFlags.swift
public static func fromEnvironment() -> Self {
    FeatureFlags(
        // Default applied here (scattered across code)
        maxTestDuration: EnvironmentVariables.maxTestDuration ?? 300,
        // ❌ Default hardcoded in multiple places
        // ❌ Risk of inconsistency
        // ❌ Hard to find what the actual default is
    )
}
```

### After: Centralized Defaults

```swift
// Layer 1: EnvironmentVariables.swift
public struct Defaults {
    public static let maxTestDuration: TimeInterval = 300  // ✅ Defined once
}

public static var maxTestDuration: TimeInterval {  // Non-optional
    guard let str = env["TEST_MAX_DURATION"],
          let duration = TimeInterval(str) else {
        return Defaults.maxTestDuration  // ✅ Default applied here
    }
    return duration
}

// Layer 2: FeatureFlags.swift
public static func fromEnvironment() -> Self {
    FeatureFlags(
        maxTestDuration: EnvironmentVariables.maxTestDuration,
        // ✅ Just use the value - no ?? needed
        // ✅ Simple and clean
        // ✅ Default already applied at Layer 1
    )
}
```

## Benefits

### 1. Single Source of Truth

All defaults in **one place**:
```swift
EnvironmentVariables.Defaults {
    public static let networkRequired: Bool = true
    public static let maxTestDuration: TimeInterval = 300
    public static let profile: String = "local"
    // ... everything here
}
```

### 2. Clean Separation of Concerns

**Layer 1:** Environment reading + default application
**Layer 2:** Value structuring and organization

Each layer has one clear responsibility.

### 3. No Nil Coalescing in Config Structs

**Before:**
```swift
FeatureFlags(
    networkRequired: env.networkRequired ?? default1,
    enableSnapshots: env.enableSnapshots ?? default2,
    maxTestDuration: env.maxTestDuration ?? default3,
    parallelExecution: env.parallelExecution ?? default4,
    verboseLogging: env.verboseLogging ?? default5,
    // ?? repeated everywhere
)
```

**After:**
```swift
FeatureFlags(
    networkRequired: env.networkRequired,
    enableSnapshots: env.enableSnapshots,
    maxTestDuration: env.maxTestDuration,
    parallelExecution: env.parallelExecution,
    verboseLogging: env.verboseLogging,
    // Clean and simple
)
```

### 4. Type Safety at the Source

Values are correctly typed **from the start**:
```swift
// Returns Bool, not String?
public static var networkRequired: Bool { ... }

// Returns TimeInterval, not TimeInterval?
public static var maxTestDuration: TimeInterval { ... }

// Returns String, not String?
public static var testProfile: String { ... }
```

No optionals to unwrap later.

### 5. Easier Testing

Can easily override defaults for testing:
```swift
// Before (required multiple ?? throughout code)
let flags = FeatureFlags(
    networkRequired: nil ?? true,
    enableSnapshots: nil ?? false,
    // ...
)

// After (values already have defaults)
let flags = FeatureFlags.fromEnvironment()
// Or override with environment variables
```

### 6. Better Documentation

The `EnvironmentVariables` struct now serves as **living documentation** of all defaults:

```swift
/// Returns whether network is required, or default if not set
public static var networkRequired: Bool {
    guard let value = env["TEST_NETWORK_REQUIRED"] else {
        return Defaults.networkRequired  // Clear what the default is
    }
    return value == "1"
}
```

## Example: Adding a New Environment Variable

### Before (Two Places to Update)

```swift
// 1. Add to EnvironmentVariables
public static var newFeature: String? {
    env["TEST_NEW_FEATURE"]
}

// 2. Add default in config struct
public static func fromEnvironment() -> Self {
    Config(
        newFeature: EnvironmentVariables.newFeature ?? "defaultValue"
        //          ❌ Default scattered away from source
    )
}
```

### After (One Place to Update)

```swift
// 1. Add default to EnvironmentVariables.Defaults
public struct Defaults {
    public static let newFeature: String = "defaultValue"
}

// 2. Add accessor with default
public static var newFeature: String {
    env["TEST_NEW_FEATURE"] ?? Defaults.newFeature
}

// 3. Use in config struct (no default needed)
public static func fromEnvironment() -> Self {
    Config(
        newFeature: EnvironmentVariables.newFeature
        // ✅ Clean - default already applied
    )
}
```

## Architecture Flow

```
User sets env var           ┌──────────────────────┐
TEST_MAX_DURATION=600 ────> │ EnvironmentVariables │
                           │                      │
                           │  1. Read env var     │
                           │  2. Parse/validate   │
                           │  3. Apply default    │
                           │     if not set       │
                           └──────────┬───────────┘
                                      │
                           Ready-to-use value
                           (TimeInterval: 600)
                                      │
                                      ▼
                           ┌──────────────────────┐
                           │   FeatureFlags       │
                           │                      │
                           │  Just consume value  │
                           │  No ?? needed         │
                           └──────────────────────┘
```

## Real-World Examples

### Example 1: Test Profile

**Layer 1:**
```swift
public static var testProfile: String {
    env["TEST_PROFILE"] ?? Defaults.profile  // "local"
}
```

**Layer 2:**
```swift
public static func fromEnvironment() -> Self {
    let profileStr = EnvironmentVariables.testProfile  // Already has default
    return TestProfile(rawValue: profileStr) ?? .local
}
```

### Example 2: Cleanup Policy

**Layer 1:**
```swift
public static var cleanupAccounts: Bool {
    guard let value = env["TEST_CLEANUP_ACCOUNTS"] else {
        return Defaults.cleanupAccounts  // true
    }
    return value == "1"
}
```

**Layer 2:**
```swift
public static func fromEnvironment() -> Self {
    CleanupPolicy(
        cleanupAccounts: EnvironmentVariables.cleanupAccounts  // Simple!
    )
}
```

### Example 3: Max Test Duration

**Layer 1:**
```swift
public static var maxTestDuration: TimeInterval {
    guard let str = env["TEST_MAX_DURATION"],
          let duration = TimeInterval(str)
    else {
        return Defaults.maxTestDuration  // 300 seconds
    }
    return duration
}
```

**Layer 2:**
```swift
public static func fromEnvironment() -> Self {
    FeatureFlags(
        maxTestDuration: EnvironmentVariables.maxTestDuration  // Clean!
    )
}
```

## Profile Overrides Still Work

The `withEnvironmentOverrides()` pattern is simplified too:

**Before:**
```swift
if let value = EnvironmentVariables.networkRequired {
    flags.networkRequired = (value == "1")  // Manual parsing
}
```

**After:**
```swift
if EnvironmentVariables.isSet("TEST_NETWORK_REQUIRED") {
    flags.networkRequired = EnvironmentVariables.networkRequired  // Already parsed
}
```

## Migration Guide

If you have custom environment variables:

1. **Add default to `EnvironmentVariables.Defaults`:**
   ```swift
   public static let myFeature: String = "defaultValue"
   ```

2. **Add accessor that returns non-optional:**
   ```swift
   public static var myFeature: String {
       env["TEST_MY_FEATURE"] ?? Defaults.myFeature
   }
   ```

3. **Use directly in config structs:**
   ```swift
   myFeature: EnvironmentVariables.myFeature  // No ?? needed
   ```

## Best Practices

1. **Always define defaults in `EnvironmentVariables.Defaults`**
   - Exception: Optional values that truly have no default (like operator credentials)

2. **Apply defaults at Layer 1 (EnvironmentVariables)**
   - Not at Layer 2 (config structs)

3. **Return non-optional values from `EnvironmentVariables`**
   - Exception: Truly optional values (operator ID, operator key)

4. **Use `isSet()` to check if env var was explicitly set**
   - Useful for overrides where you want to distinguish "not set" from "set to default"

5. **Document why each default is chosen**
   ```swift
   public static let cleanupTokens: Bool = false  // Costs HBAR with no recovery
   ```

## Summary

✅ **Defaults applied at source** (Layer 1) not at consumption (Layer 2)
✅ **Single source of truth** - All defaults in `EnvironmentVariables.Defaults`
✅ **Clean config structs** - No nil coalescing needed
✅ **Type-safe from the start** - No optionals to manage
✅ **Clear separation of concerns** - Each layer has one job
✅ **Easy to maintain** - Change default once, applies everywhere

This architecture makes the codebase simpler, more maintainable, and less error-prone.



