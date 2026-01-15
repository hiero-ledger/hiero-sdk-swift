## Summary

Implement support for [HIP-1313](https://hips.hedera.com/hip/hip-1313) which introduces high-volume throttles for entity creation transactions. This feature allows users to opt into a separate throttle system with dynamic pricing to access additional capacity during peak times.

## References

- **HIP**: https://hips.hedera.com/hip/hip-1313
- **SDK Design Document**: [hip-1313.md](https://github.com/hiero-ledger/sdk-collaboration-hub/blob/main/proposals/hips/hip-1313.md)

## Background

HIP-1313 introduces a parallel throttle system for high-volume entity creation. Users can opt into this system by setting a boolean flag on their transactions. When enabled:

- Transactions use a separate set of high-volume throttles with dedicated capacity
- Dynamic pricing applies based on throttle utilization (higher usage = higher fees)
- Users should set `maxTransactionFee` to control costs
- Standard throttles remain unchanged for users who don't opt in

## Scope

### API Changes

Add the following methods to the base `Transaction` class:

```swift
public class Transaction {
    /// Whether to use high-volume throttles for this transaction.
    /// When true, enables high-volume throttles and pricing for entity creation.
    /// Only affects supported transaction types; otherwise, it is ignored.
    public var highVolume: Bool
    
    /// Sets whether to use high-volume throttles for this transaction.
    /// - Parameter highVolume: If true, uses high-volume throttles and pricing
    /// - Returns: Self for method chaining
    @discardableResult
    public func highVolume(_ highVolume: Bool) -> Self
}
```

### Protobuf Changes

The `TransactionBody` protobuf message includes a new field:

```protobuf
message TransactionBody {
    // ... existing fields ...
    
    /**
     * If set to true, this transaction uses high-volume throttles and pricing
     * for entity creation. It only affects supported transaction types; otherwise,
     * it is ignored.
     */
    bool high_volume = 25;
}
```

**Note**: Verify that the Swift protobuf bindings are up to date with this field. If not, regenerate the protobufs.

### Supported Transaction Types

The `highVolume` flag affects the following transaction types:

| Transaction Class | Description |
|-------------------|-------------|
| `TopicCreateTransaction` | Create a new topic |
| `ContractCreateTransaction` | Create a new smart contract |
| `AccountAllowanceApproveTransaction` | Approve allowances |
| `AccountCreateTransaction` | Create a new account |
| `TransferTransaction` | Transfer (for hollow account creation) |
| `FileCreateTransaction` | Create a new file |
| `FileAppendTransaction` | Append to a file |
| `LambdaSStoreTransaction` | Store a hook |
| `ScheduleCreateTransaction` | Create a scheduled transaction |
| `TokenAirdropTransaction` | Airdrop tokens |
| `TokenAssociateTransaction` | Associate tokens to an account |
| `TokenCreateTransaction` | Create a new token |
| `TokenClaimAirdropTransaction` | Claim airdropped tokens |
| `TokenMintTransaction` | Mint tokens |

## Implementation Tasks

### 1. Update Protobufs
- [ ] Ensure `TransactionBody` protobuf includes the `high_volume` field (field number 25)
- [ ] Regenerate Swift protobuf bindings if needed

### 2. Update Transaction Base Class
- [ ] Add `highVolume` property with default value of `false`
- [ ] Add `highVolume(_ highVolume: Bool) -> Self` fluent setter method
- [ ] Add `willSet { ensureNotFrozen() }` guard to prevent modification after freezing
- [ ] Update `toTransactionBodyProtobuf` to include `highVolume` in the protobuf
- [ ] Update `init(protobuf:)` to read `highVolume` from the protobuf

### 3. Add Unit Tests
- [ ] Test that `highVolume` defaults to `false`
- [ ] Test setting `highVolume` to `true`
- [ ] Test that `highVolume` cannot be set after transaction is frozen
- [ ] Test serialization/deserialization preserves `highVolume` flag
- [ ] Test that `highVolume` is correctly included in protobuf output

### 4. Add Integration Tests
- [ ] Test creating an account with `highVolume` enabled
- [ ] Test that transaction succeeds with appropriate `maxTransactionFee`
- [ ] Test that transaction fails with `INSUFFICIENT_TX_FEE` when `maxTransactionFee` is too low

### 5. Add Example
- [ ] Create an example demonstrating high-volume account creation

## Example Usage

```swift
import Hiero

// Create an account using high-volume throttles
let accountCreateTx = try AccountCreateTransaction()
    .key(.single(newAccountKey.publicKey))
    .initialBalance(Hbar(10))
    .highVolume(true)
    .maxTransactionFee(Hbar(5))  // Important: set a fee limit
    .freezeWith(client)
    .sign(newAccountKey)

let response = try await accountCreateTx.execute(client)
let receipt = try await response.getReceipt(client)
let accountId = receipt.accountId!

print("Created account \(accountId) using high-volume throttles")
```

## Test Plan

### High-Volume Throttle Flag

1. **Given** an `AccountCreateTransaction` is configured with `highVolume(true)`, **when** the transaction is executed, **then** the account is created successfully using high-volume throttles.

2. **Given** an `AccountCreateTransaction` is configured with `highVolume(true)` and a valid `maxTransactionFee(fee)`, **when** the transaction is executed, **then** the account is created successfully and the fee charged respects the maximum transaction fee setting.

3. **Given** an `AccountCreateTransaction` is configured with `highVolume(true)` and a `maxTransactionFee(fee)` that is lower than the actual fee required, **when** the transaction is executed, **then** the transaction fails with an `INSUFFICIENT_TX_FEE` error.

## Acceptance Criteria

- [ ] `highVolume` property is available on all `Transaction` subclasses
- [ ] Setting `highVolume(true)` correctly serializes to the protobuf `high_volume` field
- [ ] Deserializing a transaction with `high_volume = true` correctly sets the `highVolume` property
- [ ] The flag cannot be modified after a transaction is frozen
- [ ] Unit tests pass for the new functionality
- [ ] Integration tests pass on testnet (when HIP-1313 is enabled)
- [ ] Example code compiles and runs successfully

## Notes

- EVM transactions that create entities are **not** included in this HIP (will be addressed in a subsequent HIP)
- High-volume transactions do not get priority processing - all transactions are processed in arrival order
- Users should always set `maxTransactionFee` when using high-volume to avoid unexpectedly high costs during peak utilization
