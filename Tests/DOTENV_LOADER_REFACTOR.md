# Dotenv Loader Refactoring

## Summary

Separated environment variable loading from test case classes into a dedicated `DotenvLoader` utility.

## Changes Made

### 1. Created `DotenvLoader` (`Tests/HieroTestSupport/Environment/DotenvLoader.swift`)

- **Purpose**: Centralized `.env` file loading independent of test infrastructure
- **Key Features**:
  - Loads `.env` once per test process (not per test case)
  - Searches up to 5 parent directories from current working directory
  - Manually sets environment variables using `setenv()` (required because `ProcessInfo.processInfo.environment` is read-only)
  - Supports verbose output when `TEST_VERBOSE=1`
  - Handles all `TEST_*` environment variables

### 2. Updated `HieroTestCase.swift`

- **Before**: Had a large `static let dotenvEnvironment` property with inline `.env` loading logic
- **After**: Simply calls `DotenvLoader.ensureLoaded()` in `setUp()`
- **Benefits**:
  - Cleaner separation of concerns
  - Removed dependency on `SwiftDotenv` import in test case
  - Environment loading is now reusable across different contexts

### 3. Cleaned up `TestEnvironmentConfig.swift`

- Removed unused `import SwiftDotenv`
- No longer responsible for `.env` loading

## Architecture Benefits

### Separation of Concerns
- Environment loading logic is independent of test case hierarchy
- Can be used by any code that needs `.env` support, not just test cases

### Single Responsibility
- `DotenvLoader`: Handle `.env` file discovery and loading
- `HieroTestCase`: Manage test case lifecycle and configuration
- `TestEnvironmentConfig`: Parse and validate environment configuration

### Performance
- Static property ensures `.env` is loaded exactly once per process
- No redundant file searches or parsing across test cases

### Maintainability
- All `.env` loading logic in one place
- Easy to add new environment variables to the loader
- Clear debugging with optional verbose output

## Usage

The loader is automatically invoked when any test case runs:

```swift
open class HieroTestCase: XCTestCase {
    open override func setUp() async throws {
        try await super.setUp()
        
        // Ensure .env is loaded before config
        DotenvLoader.ensureLoaded()
        
        config = try TestEnvironmentConfig.fromEnvironment()
    }
}
```

You can also manually invoke it if needed:

```swift
// In any Swift code
DotenvLoader.ensureLoaded()
// Now all TEST_* environment variables are available
```

## Environment Variables Loaded

The loader automatically sets the following environment variables from `.env`:

- `TEST_OPERATOR_ID`
- `TEST_OPERATOR_KEY`
- `TEST_PROFILE`
- `TEST_NETWORK_NAME`
- `TEST_CONSENSUS_NODES`
- `TEST_CONSENSUS_NODE_ACCOUNT_IDS`
- `TEST_MIRROR_NODES`
- `TEST_VERBOSE`
- `TEST_ENABLE_SNAPSHOTS`
- `TEST_ALLOW_PARALLEL_EXECUTION`
- `TEST_CLEANUP_ACCOUNTS`
- `TEST_CLEANUP_TOKENS`
- `TEST_CLEANUP_FILES`
- `TEST_CLEANUP_CONTRACTS`
- `TEST_CLEANUP_TOPICS`

## Verbose Mode

Set `TEST_VERBOSE=1` in your `.env` or environment to see debug output:

```bash
🔍 Searching for .env file starting from: /Users/you/project
✓ Loaded .env from: /Users/you/project/.env
```

Without verbose mode, the loader runs silently.

