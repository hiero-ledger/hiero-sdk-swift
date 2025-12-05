# Centralized Defaults

## Overview

All default values for test configuration are now centralized in a single file: `TestDefaults.swift`. This provides a single source of truth that is referenced by all configuration components.

## Motivation

Previously, defaults were scattered across multiple files:
- `EnvironmentVariables` had a private `Defaults` struct
- `FeatureFlags.defaults` hardcoded values
- `CleanupPolicy.economical` hardcoded values
- `NetworkConfig` hardcoded local network values

This created:
- ❌ **Duplication** - Same values defined in multiple places
- ❌ **Risk of drift** - Easy for defaults to become inconsistent
- ❌ **Maintenance burden** - Changing a default required updating multiple files

## Solution: `TestDefaults.swift`

All defaults are now defined in a single public struct:

```swift
public struct TestDefaults {
    // Test Profile
    public static let profile: String = "local"
    
    // Feature Flags
    public static let networkRequired: Bool = true
    public static let enableSnapshots: Bool = true
    public static let maxTestDuration: TimeInterval = 300
    public static let parallelExecution: Bool = true
    public static let verboseLogging: Bool = false
    
    // Cleanup Policy
    public static let cleanupAccounts: Bool = true
    public static let cleanupTokens: Bool = false
    public static let cleanupFiles: Bool = false
    public static let cleanupTopics: Bool = false
    public static let cleanupContracts: Bool = true
    
    // Local Network Configuration
    public static let localConsensusNode: String = "127.0.0.1:50211"
    public static let localConsensusNodeAccountId: String = "0.0.3"
    public static let localMirrorNode: String = "127.0.0.1:5600"
}
```

## Components Using TestDefaults

### 1. EnvironmentVariables

References `TestDefaults` when environment variables are not set:

```swift
public static var testProfile: String {
    env["TEST_PROFILE"] ?? TestDefaults.profile
}

public static var networkRequired: Bool {
    if let value = env["TEST_NETWORK_REQUIRED"] {
        return value == "1"
    }
    return TestDefaults.networkRequired
}
```

### 2. FeatureFlags

Uses `TestDefaults` in its `.defaults` static property:

```swift
public static var defaults: Self {
    FeatureFlags(
        networkRequired: TestDefaults.networkRequired,
        enableSnapshots: TestDefaults.enableSnapshots,
        maxTestDuration: TestDefaults.maxTestDuration,
        parallelExecution: TestDefaults.parallelExecution,
        verboseLogging: TestDefaults.verboseLogging,
        cleanupPolicy: .economical
    )
}
```

### 3. CleanupPolicy

References `TestDefaults` in its `.economical` policy:

```swift
public static var economical: Self {
    CleanupPolicy(
        cleanupAccounts: TestDefaults.cleanupAccounts,
        cleanupTokens: TestDefaults.cleanupTokens,
        cleanupFiles: TestDefaults.cleanupFiles,
        cleanupTopics: TestDefaults.cleanupTopics,
        cleanupContracts: TestDefaults.cleanupContracts
    )
}
```

### 4. NetworkConfig

Uses `TestDefaults` for local network configuration:

```swift
} else if type == .local {
    // Local defaults from TestDefaults.swift
    if let accountId = try? AccountId.fromString(TestDefaults.localConsensusNodeAccountId) {
        nodes = [TestDefaults.localConsensusNode: accountId]
    }
}
```

## Benefits

✅ **Single Source of Truth** - All defaults defined in one place  
✅ **No Duplication** - Values referenced, not duplicated  
✅ **Easy to Maintain** - Change a default in one place, it updates everywhere  
✅ **Clear Documentation** - One file to understand all defaults  
✅ **Type Safety** - Compile-time references ensure consistency  

## Usage Patterns

### For Builders
```swift
private var featureFlags: FeatureFlags = .defaults
```

### For Environment Loading
```swift
public static var maxTestDuration: TimeInterval {
    if let value = env["TEST_MAX_DURATION"] {
        return TimeInterval(value) ?? TestDefaults.maxTestDuration
    }
    return TestDefaults.maxTestDuration
}
```

### For Predefined Policies
```swift
public static var economical: Self {
    CleanupPolicy(
        cleanupAccounts: TestDefaults.cleanupAccounts,
        // ... other fields from TestDefaults
    )
}
```

## Architecture

```
TestDefaults.swift (source of truth)
    ↓ referenced by
    ├── EnvironmentVariables.swift (applies defaults when env vars not set)
    ├── FeatureFlags.swift (.defaults static property)
    ├── CleanupPolicy.swift (.economical policy)
    └── NetworkConfig.swift (local network defaults)
```

## Migration Notes

All previous hardcoded defaults have been replaced with `TestDefaults` references. No behavioral changes were made - this was purely a refactoring to centralize the values.
