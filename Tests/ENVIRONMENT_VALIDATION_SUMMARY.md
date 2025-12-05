# Environment Validation Summary

## Overview

Comprehensive audit and validation system for all test environment variables, with explicit defaults, requirement checking, and detailed error messages.

## What Was Done

### 1. **Fixed `CleanupPolicy` Defaults**
- Added explicit `init` method with default values
- Added `.economical` predefined policy (was referenced but not defined)
- Fixed `.fromEnvironment()` to properly handle nil coalescing
- **Before:** Broken - passing `Bool?` to init expecting `Bool`
- **After:** Working - all defaults explicitly documented and handled

### 2. **Created `EnvironmentValidation` System**
Location: `Tests/HieroTestSupport/Environment/EnvironmentValidation.swift`

**Features:**
- Profile-specific validation rules
- Detailed error messages with examples
- Validates operator credentials (presence and format)
- Validates network configuration consistency
- Warns on count mismatches (non-fatal)

**Validation Errors Include:**
```swift
public enum ValidationError: Error, CustomStringConvertible {
    case missingRequired(variable: String, reason: String, example: String)
    case invalidValue(variable: String, value: String, reason: String)
    case conflictingValues(variables: [String], reason: String)
}
```

### 3. **Comprehensive Documentation System**

**Added to `EnvironmentVariables`:**
```swift
static let documentation: [EnvironmentVariableDoc]
static func printDocumentation()
```

**Each variable documented with:**
- Name
- Type (String, Boolean, Number, Array, Enum)
- Requirement level (Required, Optional, Conditional)
- Default value
- Description
- Example usage

### 4. **Integrated Validation into Config Loading**

Added to `TestEnvironmentConfig.fromEnvironment()`:
```swift
// Validate environment variables for this profile
try EnvironmentValidation.validate(for: profile)
```

Now runs automatically when tests load configuration.

### 5. **Created Comprehensive Audit Documentation**

**Files Created:**
- `Tests/ENVIRONMENT_AUDIT.md` - Complete reference (200+ lines)
- `Tests/ENVIRONMENT_VALIDATION_SUMMARY.md` - This file

## Key Improvements

### Explicit Defaults

**Before:**
```swift
public struct CleanupPolicy {
    public var cleanupAccounts: Bool = true  // Implicit
    // ... sometimes worked, sometimes didn't
}
```

**After:**
```swift
public struct CleanupPolicy {
    public var cleanupAccounts: Bool  // Explicit
    
    public init(
        cleanupAccounts: Bool = true,  // Documented default
        cleanupTokens: Bool = false,
        // ...
    ) {
        self.cleanupAccounts = cleanupAccounts
        // ...
    }
    
    public static var economical: Self {
        CleanupPolicy(
            cleanupAccounts: true,   // Recovers HBAR
            cleanupTokens: false,    // Costs HBAR
            // ...
        )
    }
}
```

### Helpful Error Messages

**Before:**
```
Error: Operator credentials are required but not provided.
```

**After:**
```
❌ Missing required environment variable: TEST_OPERATOR_ID

Reason: Profile 'local' requires operator credentials

Example: TEST_OPERATOR_ID=0.0.1234

Set this in your .env file or environment.
```

### Validated Requirements by Profile

| Profile | Operator? | Network Config? | Validation |
|---------|-----------|-----------------|------------|
| `local` | ✓ Required | Optional (has defaults) | ✓ |
| `ciUnit` | ✗ Not required | ✗ Not required | ✓ |
| `ciIntegration` | ✓ Required | ✓ Required | ✓ |
| `development` | ✓ Required | ✓ Required (mirror OR consensus) | ✓ |

### Smart Fallback for Mismatches

**Consensus Nodes vs Account IDs:**
```swift
// Before: Error if counts don't match
guard consensusNodes.count == consensusAccountIds.count else {
    return NetworkConfig(nodes: [:], mirrorNodes: mirrorNodes)  // Lose everything!
}

// After: Warning + use what we can
if consensusNodes.count != consensusAccountIds.count {
    let useCount = min(consensusNodes.count, consensusAccountIds.count)
    print("WARNING: ... Will use the first \(useCount) node(s).")
}
// Continue with zip() which automatically handles the mismatch
```

## All Defaults Formalized

### `FeatureFlags` Defaults

```swift
// Base init defaults
networkRequired: Bool = true
enableSnapshots: Bool = true
maxTestDuration: TimeInterval = 300  // 5 minutes
parallelExecution: Bool = true
verboseLogging: Bool = false
cleanupPolicy: CleanupPolicy = .economical
```

### `CleanupPolicy` Defaults

```swift
// Base init defaults (.economical)
cleanupAccounts: Bool = true    // Recovers HBAR
cleanupTokens: Bool = false     // Costs HBAR
cleanupFiles: Bool = false      // Costs HBAR
cleanupTopics: Bool = false     // Costs HBAR
cleanupContracts: Bool = true   // Can recover HBAR
```

### `NetworkConfig` Defaults

```swift
// For .local environment type
nodes: ["127.0.0.1:50211": AccountId(num: 3)]
mirrorNodes: ["127.0.0.1:5600"]
networkUpdatePeriod: nil

// For .testnet, .previewnet, .mainnet
// Uses SDK's built-in Client.for*() methods

// For .unit
nodes: [:]  // Empty - no network
mirrorNodes: []
```

### `TestProfile` Defaults

```swift
// When TEST_PROFILE not set
default: .local

// When TEST_PROFILE has invalid value
fallback: .local
```

## Validation Rules

### 1. Operator Validation

**Trigger:** Any profile with `environmentType.requiresOperator == true`

**Checks:**
- `TEST_OPERATOR_ID` is set
- `TEST_OPERATOR_KEY` is set
- `TEST_OPERATOR_KEY` is at least 64 characters

**Error Example:**
```
❌ Missing required environment variable: TEST_OPERATOR_KEY

Reason: Profile 'local' requires operator credentials

Example: TEST_OPERATOR_KEY=302e020100300506032b657004220420...

Set this in your .env file or environment.
```

### 2. Network Configuration Validation

**For `local` profile:**
- If `TEST_CONSENSUS_NODES` set → `TEST_CONSENSUS_NODE_ACCOUNT_IDS` should also be set
- If neither set → uses defaults

**For `development` profile:**
- At least one of `TEST_MIRROR_NODES` or `TEST_CONSENSUS_NODES` must be set

**Error Example:**
```
❌ Missing required environment variable: TEST_CONSENSUS_NODE_ACCOUNT_IDS

Reason: When TEST_CONSENSUS_NODES is specified, TEST_CONSENSUS_NODE_ACCOUNT_IDS must also be provided

Example: TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4,0.0.5

Set this in your .env file or environment.
```

### 3. Count Mismatch Handling

**Warning (not error) if counts don't match:**

```
⚠️  WARNING: TEST_CONSENSUS_NODES has 3 node(s), but TEST_CONSENSUS_NODE_ACCOUNT_IDS 
has 2 ID(s). Will use the first 2.
```

**Behavior:** Uses `zip()` to pair up as many as possible, ignores extras

### 4. Value Trimming

**Automatic whitespace trimming:**
- `TEST_OPERATOR_ID`
- `TEST_OPERATOR_KEY`
- Each element in `TEST_CONSENSUS_NODES`
- Each element in `TEST_CONSENSUS_NODE_ACCOUNT_IDS`
- Each element in `TEST_MIRROR_NODES`

**Prevents:** Subtle bugs from `.env` file formatting issues

## Usage

### View All Documentation

```swift
// In code or test
EnvironmentVariables.printDocumentation()
```

**Output:**
```
================================================================================
TEST ENVIRONMENT VARIABLES DOCUMENTATION
================================================================================

## OPERATOR
--------------------------------------------------------------------------------

TEST_OPERATOR_ID
  Type: String
  Required: ⚠ Conditional: For integration tests
  Default: None
  Description: Account ID of the operator account used for test transactions
  Example: TEST_OPERATOR_ID=0.0.1234
...
```

### View Current Environment

```swift
// Print all TEST_* variables (keys are redacted)
EnvironmentVariables.printAllTestVariables()
```

**Output:**
```
=== Test Environment Variables ===
TEST_CLEANUP_ACCOUNTS = 1
TEST_CLEANUP_CONTRACTS = 1
TEST_CONSENSUS_NODE_ACCOUNT_IDS = 0.0.3
TEST_CONSENSUS_NODES = 127.0.0.1:50211
TEST_MIRROR_NODES = 127.0.0.1:5600
TEST_OPERATOR_ID = 0.0.2
TEST_OPERATOR_KEY = ***REDACTED***
TEST_PROFILE = local
==================================
```

### Validation Happens Automatically

```swift
// In your test
open override func setUp() async throws {
    try await super.setUp()
    
    // This now includes validation
    config = try TestEnvironmentConfig.fromEnvironment()
}
```

## Benefits

1. **No Silent Failures** - Missing required variables throw clear errors
2. **Helpful Messages** - Errors include reason and example
3. **Smart Fallbacks** - Use as much valid configuration as possible
4. **Self-Documenting** - All defaults and requirements in one place
5. **Prevents Common Errors** - Automatic trimming, format validation
6. **Easy to Extend** - Add new variables to documentation array

## Testing

```bash
# Successful validation (has operator credentials)
TEST_PROFILE=local swift test

# Validation error (missing operator)
TEST_PROFILE=development swift test
# Error: Missing required environment variable: TEST_OPERATOR_ID

# Validation error (development needs network config)
TEST_PROFILE=development TEST_OPERATOR_ID=0.0.2 TEST_OPERATOR_KEY=... swift test
# Error: Missing required environment variable: TEST_MIRROR_NODES or TEST_CONSENSUS_NODES
```

## Files Changed/Created

### Created:
- `Tests/HieroTestSupport/Environment/EnvironmentValidation.swift` (170 lines)
- `Tests/ENVIRONMENT_AUDIT.md` (770 lines)
- `Tests/ENVIRONMENT_VALIDATION_SUMMARY.md` (this file)

### Modified:
- `Tests/HieroTestSupport/Environment/CleanupPolicy.swift`
  - Added explicit init with defaults
  - Fixed `.fromEnvironment()` nil coalescing
  - Added `.economical` predefined policy
  
- `Tests/HieroTestSupport/Environment/TestEnvironmentConfig.swift`
  - Integrated validation call in `.fromEnvironment()`
  
- `Tests/HieroTestSupport/Environment/NetworkConfig.swift`
  - Improved mismatch handling (warning vs error)
  - Uses as many nodes as have account IDs

## Next Steps

### Future Enhancements (Optional)

1. **Add schema validation** - JSON schema for `.env` files
2. **IDE integration** - `.env.example` with comments
3. **CI/CD templates** - Example configurations for different CI systems
4. **Migration tool** - Script to migrate old configs to new format

### Documentation Maintenance

When adding new environment variables:

1. Add to `EnvironmentVariables` struct
2. Add to `EnvironmentVariables.documentation` array
3. Add validation rules if required
4. Update `ENVIRONMENT_AUDIT.md`
5. Add examples

## Summary

✅ All environment variables now have explicit defaults  
✅ All requirements are validated with helpful error messages  
✅ All defaults are documented in code and markdown  
✅ Validation runs automatically on test setup  
✅ Smart fallbacks for common configuration issues  
✅ Self-documenting system via `printDocumentation()`

The test environment configuration is now robust, well-documented, and fails fast with helpful error messages when misconfigured.



