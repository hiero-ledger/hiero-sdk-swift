# Account Creation Helpers Added to HieroIntegrationTestCase

## Overview

Added reusable account creation and cleanup helper methods to `HieroIntegrationTestCase` base class, making them available to all integration tests.

## New Methods

### 1. `createAccountAndRegisterCleanup(_:key:)`

A comprehensive helper that combines three common operations:
- Executes an `AccountCreateTransaction`
- Safely unwraps the account ID using `XCTUnwrap`
- Registers the account for automatic cleanup

**Signature:**
```swift
public func createAccountAndRegisterCleanup(
    _ transaction: AccountCreateTransaction,
    key: PrivateKey
) async throws -> AccountId
```

**Usage:**
```swift
let key = PrivateKey.generateEd25519()

let accountId = try await createAccountAndRegisterCleanup(
    AccountCreateTransaction()
        .keyWithoutAlias(.single(key.publicKey))
        .initialBalance(Hbar(1)),
    key: key
)
```

**Works with complex transactions:**
```swift
let accountId = try await createAccountAndRegisterCleanup(
    try AccountCreateTransaction()
        .receiverSignatureRequired(true)
        .keyWithAlias(.single(key.publicKey), ecdsaKey)
        .freezeWith(testEnv.client)
        .sign(key)
        .sign(ecdsaKey),
    key: key
)
```

### 2. `registerAccountForCleanup(accountId:key:)`

Register an existing account for automatic cleanup at test teardown.

**Signature:**
```swift
public func registerAccountForCleanup(
    accountId: AccountId,
    key: PrivateKey
) async
```

**Usage:**
```swift
// When you already have an account ID
await registerAccountForCleanup(accountId: accountId, key: key)
```

## Benefits

1. **Less Boilerplate**: Each test is ~4 lines shorter
2. **Safer**: Enforces `XCTUnwrap` pattern automatically - no force unwraps
3. **More Readable**: Test intent is clearer
4. **Consistent**: All tests follow the same pattern
5. **Reusable**: Available to all integration test classes
6. **Proper Cleanup**: Ensures accounts are deleted at teardown according to cleanup policy

## Implementation Details

- Both methods are `public` members of `HieroIntegrationTestCase`
- `createAccountAndRegisterCleanup` handles transaction execution and safe unwrapping
- `registerAccountForCleanup` uses `ResourceManager.registerCleanup` with priority 100
- Cleanup executes `AccountDeleteTransaction` with proper key signing
- The cleanup closure properly captures variables to avoid reference issues

## Tests Updated

The following test file has been updated to use these helpers:
- **`Tests/HieroIntegrationTests/Account/AccountCreate.swift`** (10 test methods simplified)

## Future Work

Other integration test files that create accounts can be refactored to use these helpers:
- Token integration tests (accounts for token operations)
- File integration tests (accounts for file operations)
- Topic integration tests (accounts for topic operations)
- Contract integration tests (accounts for contract deployment)

Simply search for patterns like:
```swift
let receipt = try await AccountCreateTransaction()
    // ...
    .execute(testEnv.client)
    .getReceipt(testEnv.client)

let accountId = receipt.accountId!  // or try XCTUnwrap(receipt.accountId)
```

And replace with:
```swift
let accountId = try await createAccountAndRegisterCleanup(
    AccountCreateTransaction()
        // ...
    ,
    key: key
)
```

## Files Modified

- **`Tests/HieroTestSupport/Base/HieroIntegrationTestCase.swift`**: Added helper methods, removed `IntegrationTestEnvironment` (moved to separate file)
- **`Tests/HieroTestSupport/Environment/IntegrationTestEnvironment.swift`**: Created new file for better separation of concerns
- **`Tests/HieroIntegrationTests/Account/AccountCreate.swift`**: Removed duplicate methods, now uses inherited helpers

