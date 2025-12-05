# Token Key Management Proposal

## Problem Statement

Currently, token integration tests require developers to manually generate keys even when they don't need them:

```swift
// Current: Test generates keys it NEVER uses, just for cleanup
let adminKey = PrivateKey.generateEd25519()
let supplyKey = PrivateKey.generateEd25519()
let wipeKey = PrivateKey.generateEd25519()
let tokenId = try await createToken(
    TokenCreateTransaction()
        .name("Test Token")
        .symbol("TT")
        .treasuryAccountId(testEnv.operator.accountId)
        .adminKey(.single(adminKey.publicKey))
        .supplyKey(.single(supplyKey.publicKey))
        .wipeKey(.single(wipeKey.publicKey))
        .initialSupply(1000)
        .sign(adminKey),
    adminKey: adminKey,
    supplyKey: supplyKey,
    wipeKey: wipeKey
)

// Test only does transfers - never uses adminKey, supplyKey, or wipeKey!
```

**Key insight from analysis:**
- **adminKey**: ~90% of usages are pure boilerplate (only used for creation/cleanup)
- **wipeKey**: ~75% of usages are pure boilerplate
- **supplyKey**: ~45% of usages are pure boilerplate

## Goals

1. **Tests only see keys they use** - No boilerplate key generation
2. **Automatic cleanup** - All tokens clean up properly
3. **Explicit when needed** - Tests that need keys can still access them
4. **Backward compatible** - Existing tests continue to work

---

## Proposed Solution: Implicit Key Generation

### Core Principle

**If a key is only needed for token creation and cleanup, `createToken` generates it internally. If a test actually uses a key, the test generates and passes it.**

This means:
- Test code directly reflects test intent
- Keys that appear in test code are keys the test actually uses
- Cleanup "just works" without exposing implementation details

### Two Functions, Clear Purpose

| Function | Purpose | Key Management |
|----------|---------|----------------|
| `createToken` | Standard test tokens with automatic cleanup | Auto-generates cleanup keys (admin, supply, wipe, pause) |
| `createUnmanagedToken` | Full manual control | No key management - test handles everything |

### Which Keys Are Auto-Generated?

**Auto-generated if not provided** (cleanup-essential):
- **adminKey** - Required to delete token
- **supplyKey** - Required to burn supply before deletion  
- **wipeKey** - Required to wipe balances from non-treasury accounts

**Registered for cleanup if provided, but NOT auto-generated**:
- **pauseKey** - If test provides it, register for cleanup (to unpause before deletion). If not provided, token won't be paused so no unpause needed.

**Never managed by `createToken`** (test always uses these):
- **freezeKey** - If a test needs freeze, it will use it
- **kycKey** - If a test needs KYC, it will use it
- **feeScheduleKey** - If a test needs fee schedules, it will use it
- **metadataKey** - If a test needs metadata updates, it will use it

The key insight for `pauseKey`: unlike admin/supply/wipe which are often only needed for cleanup, if a test generates a `pauseKey` it's going to actually use it (to test pause/unpause behavior). So we don't waste time generating one if the test doesn't need it.

### How It Works

The `createToken` function signature:

```swift
func createToken(
    _ transaction: TokenCreateTransaction,
    adminKey: PrivateKey? = nil,      // If nil, auto-generate
    supplyKey: PrivateKey? = nil,     // If nil, auto-generate
    wipeKey: PrivateKey? = nil,       // If nil, auto-generate
    pauseKey: PrivateKey? = nil       // If nil, do NOT generate (test doesn't need pause)
) async throws -> TokenId
```

**Behavior:**
1. If `adminKey` is `nil`, `createToken` generates one, attaches it to the transaction, signs with it, and registers it for cleanup
2. If `adminKey` is provided, `createToken` uses that key (assumes it's already attached to transaction), registers it for cleanup
3. Same logic for supplyKey and wipeKey
4. **pauseKey is different**: if `nil`, do nothing (token won't have pause capability). If provided, register it for cleanup (so token gets unpaused before deletion)

**`createUnmanagedToken`** remains available for tests that want full manual control:

```swift
func createUnmanagedToken(_ transaction: TokenCreateTransaction) async throws -> TokenId
```

This is useful for:
- Testing tokens without certain keys (e.g., immutable tokens with no adminKey)
- Edge cases where automatic key management would interfere
- Tests that want explicit control over everything

---

## Example: Before & After

### Test that doesn't use any keys (token transfer)

```swift
// BEFORE: Verbose, generates keys test never uses
let adminKey = PrivateKey.generateEd25519()
let supplyKey = PrivateKey.generateEd25519()
let wipeKey = PrivateKey.generateEd25519()
let tokenId = try await createToken(
    TokenCreateTransaction()
        .name("Test")
        .symbol("T")
        .treasuryAccountId(testEnv.operator.accountId)
        .adminKey(.single(adminKey.publicKey))
        .supplyKey(.single(supplyKey.publicKey))
        .wipeKey(.single(wipeKey.publicKey))
        .initialSupply(1000)
        .sign(adminKey),
    adminKey: adminKey,
    supplyKey: supplyKey,
    wipeKey: wipeKey
)

// AFTER: Clean - only specify what matters for the test
let tokenId = try await createToken(
    TokenCreateTransaction()
        .name("Test")
        .symbol("T")
        .treasuryAccountId(testEnv.operator.accountId)
        .initialSupply(1000)
)
// Keys auto-generated internally, cleanup works automatically
```

### Test that uses supplyKey (minting test)

```swift
// BEFORE: Same verbose setup
let adminKey = PrivateKey.generateEd25519()
let supplyKey = PrivateKey.generateEd25519()
let tokenId = try await createToken(
    TokenCreateTransaction()
        ...
        .adminKey(.single(adminKey.publicKey))
        .supplyKey(.single(supplyKey.publicKey))
        .sign(adminKey),
    adminKey: adminKey,
    supplyKey: supplyKey
)

_ = try await TokenMintTransaction()
    .tokenId(tokenId)
    .amount(100)
    .sign(supplyKey)  // Test actually uses this
    .execute(client)

// AFTER: Only generate the key you use
let supplyKey = PrivateKey.generateEd25519()
let tokenId = try await createToken(
    TokenCreateTransaction()
        .name("Test")
        .symbol("T")
        .treasuryAccountId(testEnv.operator.accountId)
        .supplyKey(.single(supplyKey.publicKey)),
    supplyKey: supplyKey  // Pass it because we use it
)
// adminKey, wipeKey auto-generated internally

_ = try await TokenMintTransaction()
    .tokenId(tokenId)
    .amount(100)
    .sign(supplyKey)
    .execute(client)
```

### Test that uses adminKey (update test)

```swift
// Test generates adminKey because it uses it for TokenUpdateTransaction
let adminKey = PrivateKey.generateEd25519()
let tokenId = try await createToken(
    TokenCreateTransaction()
        .name("Original")
        .symbol("O")
        .treasuryAccountId(testEnv.operator.accountId)
        .adminKey(.single(adminKey.publicKey))
        .sign(adminKey),
    adminKey: adminKey  // Pass it because we use it
)
// supplyKey, wipeKey auto-generated internally for cleanup

_ = try await TokenUpdateTransaction()
    .tokenId(tokenId)
    .tokenName("Updated")
    .sign(adminKey)  // Test uses adminKey here
    .execute(client)
```

### Test that uses freezeKey (freeze test)

```swift
// freezeKey is NOT auto-generated - test defines it because it uses it
let freezeKey = PrivateKey.generateEd25519()
let tokenId = try await createToken(
    TokenCreateTransaction()
        .name("Test")
        .symbol("T")
        .treasuryAccountId(testEnv.operator.accountId)
        .freezeKey(.single(freezeKey.publicKey))
)
// adminKey, supplyKey, wipeKey auto-generated
// freezeKey is NOT auto-generated - test manages it

_ = try await TokenFreezeTransaction()
    .tokenId(tokenId)
    .accountId(aliceId)
    .sign(freezeKey)  // Test uses freezeKey
    .execute(client)
```

### Test for immutable token (uses createUnmanagedToken)

```swift
// Use createUnmanagedToken for tokens without adminKey
let tokenId = try await createUnmanagedToken(
    TokenCreateTransaction()
        .name("Immutable")
        .symbol("IMM")
        .treasuryAccountId(testEnv.operator.accountId)
        // No adminKey - this is an immutable token
)

// Test verifies immutable behavior...
```

---

## Implementation Details

```swift
func createToken(
    _ transaction: TokenCreateTransaction,
    adminKey: PrivateKey? = nil,
    supplyKey: PrivateKey? = nil,
    wipeKey: PrivateKey? = nil,
    pauseKey: PrivateKey? = nil
) async throws -> TokenId {
    var tx = transaction
    
    // Generate adminKey if not provided (always needed for cleanup)
    let effectiveAdminKey = adminKey ?? PrivateKey.generateEd25519()
    if adminKey == nil {
        tx = tx.adminKey(.single(effectiveAdminKey.publicKey))
    }
    
    // Generate supplyKey if not provided (needed for burn during cleanup)
    let effectiveSupplyKey = supplyKey ?? PrivateKey.generateEd25519()
    if supplyKey == nil {
        tx = tx.supplyKey(.single(effectiveSupplyKey.publicKey))
    }
    
    // Generate wipeKey if not provided (needed for wipe during cleanup)
    let effectiveWipeKey = wipeKey ?? PrivateKey.generateEd25519()
    if wipeKey == nil {
        tx = tx.wipeKey(.single(effectiveWipeKey.publicKey))
    }
    
    // pauseKey: do NOT auto-generate
    // If test needs pause, it will provide the key and use it
    // If test doesn't need pause, token shouldn't have pause capability
    
    // Sign with adminKey if we generated it (caller didn't sign)
    if adminKey == nil {
        tx = tx.sign(effectiveAdminKey)
    }
    
    // Create the token
    let tokenId = try await createUnmanagedToken(tx)
    
    // Register cleanup keys
    await resourceManager.registerAdminKey(effectiveAdminKey, for: tokenId)
    await resourceManager.registerSupplyKey(effectiveSupplyKey, for: tokenId)
    await resourceManager.registerWipeKey(effectiveWipeKey, for: tokenId)
    
    // Only register pauseKey if provided (test needs pause functionality)
    if let pauseKey = pauseKey {
        await resourceManager.registerPauseKey(pauseKey, for: tokenId)
    }
    
    return tokenId
}
```

---

## Summary

| Scenario | What to use | Keys in test code |
|----------|-------------|-------------------|
| Simple token, no key usage | `createToken(tx)` | None |
| Need to mint/burn | `createToken(tx, supplyKey: key)` | Just supplyKey |
| Need to update token | `createToken(tx, adminKey: key)` | Just adminKey |
| Need to pause/unpause | `createToken(tx, pauseKey: key)` | Just pauseKey |
| Need freeze/KYC/etc | `createToken(tx)` + define freezeKey | Just freezeKey |
| Immutable token (no adminKey) | `createUnmanagedToken(tx)` | None (manual) |
| Full manual control | `createUnmanagedToken(tx)` | All (manual) |

---

## Pros & Cons

### Pros

1. **Minimal boilerplate** - Tests only show keys they actually use
2. **Self-documenting** - If a key appears in test code, the test uses it
3. **Backward compatible** - Tests can still pass keys if they prefer
4. **Cleanup always works** - Required keys are always generated internally
5. **No new types** - Still returns `TokenId`, not a wrapper struct
6. **Gradual migration** - Can update tests one at a time
7. **Escape hatch** - `createUnmanagedToken` for edge cases

### Cons

1. **Implicit behavior** - Keys are generated "magically" which could confuse newcomers
2. **Slight overhead** - Generates 3 keys (admin, supply, wipe) even when test doesn't need them (negligible for tests)
3. **Transaction mutation** - `createToken` modifies the transaction, which might be unexpected

---

## Migration Strategy

1. Update `createToken` signature (make key params optional with nil defaults)
2. Existing tests continue to work (they pass keys explicitly)
3. Gradually simplify tests that don't use their keys
4. Eventually, most tests become much cleaner
