# Magic Numbers Audit in Integration Tests

This document catalogs magic numbers found in the integration tests that could potentially be replaced with named constants in `TestConstants.swift`.

## Already Defined Constants

These constants are already defined in `TestConstants.swift`:
- `testAmount` = 100 (Int64)
- `testMintedNfts` = 10 (Int64)
- `testFungibleInitialBalance` = 1_000_000 (UInt64)
- `testMetadata` = Array(repeating: Data([9, 1, 6]), count: 10)

---

## Token Configuration Magic Numbers

### `.decimals(3)`
**Used in:** 39 occurrences across multiple files
- TokenRejectTransactionIntegrationTests.swift (8)
- TokenAirdropTransactionIntegrationTests.swift (8)
- TokenCancelAirdropTransactionIntegrationTests.swift (9)
- TokenClaimAirdropTransactionIntegrationTests.swift (7)
- TokenRejectFlowIntegrationTests.swift (1)
- TokenInfoQueryIntegrationTests.swift (1)
- TokenTransferIntegrationTests.swift (2)
- TokenCreateTransactionIntegrationTests.swift (1)

**Recommendation:** Create `testTokenDecimals: UInt32 = 3`

### `.initialSupply(10)`
**Used in:** 6 occurrences
- TokenBurnTransactionIntegrationTests.swift (1)
- TokenWipeTransactionIntegrationTests.swift (2)
- TokenTransferIntegrationTests.swift (4)

**Recommendation:** Create `testSmallInitialSupply: UInt64 = 10`

### `.initialSupply(0)`
**Used in:** 4 occurrences
- TokenBurnTransactionIntegrationTests.swift (1)
- TokenInfoQueryIntegrationTests.swift (1)
- TokenCreateTransactionIntegrationTests.swift (1)
- ScheduleSignTransactionIntegrationTests.swift (1)

**Recommendation:** These are intentionally zero for NFT tokens - likely no constant needed

### `.initialSupply(1)`
**Used in:** 1 occurrence
- TokenTransferIntegrationTests.swift

**Recommendation:** Specific test case - likely no constant needed

### `.maxSupply(5000)`
**Used in:** 3 occurrences
- TokenInfoQueryIntegrationTests.swift (1)
- TokenMintTransactionIntegrationTests.swift (2)

**Recommendation:** Create `testMaxSupply: UInt64 = 5000`

### `.maxSupply(5)`
**Used in:** 1 occurrence
- TokenMintTransactionIntegrationTests.swift

**Recommendation:** Specific test case - likely no constant needed

---

## Token Transfer Magic Numbers

### `.tokenTransfer(..., 10)` / `.tokenTransfer(..., -10)`
**Used in:** 34 occurrences across multiple files
- TokenRejectTransactionIntegrationTests.swift (14)
- TokenRejectFlowIntegrationTests.swift (4)
- TokenWipeTransactionIntegrationTests.swift (4)
- TokenTransferIntegrationTests.swift (8)
- AccountUpdateTransactionIntegrationTests.swift (2)

**Recommendation:** Create `testTransferAmount: Int64 = 10`

### `.tokenTransfer(..., 1)` / `.tokenTransfer(..., -1)`
**Used in:** 4 occurrences
- TokenTransferIntegrationTests.swift

**Recommendation:** Specific test case - likely no constant needed

---

## Token Operations Magic Numbers

### `.amount(10)` (for burn/wipe/mint)
**Used in:** 6 occurrences
- TokenBurnTransactionIntegrationTests.swift (2)
- TokenWipeTransactionIntegrationTests.swift (3)
- TokenMintTransactionIntegrationTests.swift (2)
- ScheduleSignTransactionIntegrationTests.swift (1)

**Recommendation:** Could use same `testTransferAmount` or create `testOperationAmount: UInt64 = 10`

### `.amount(0)` and `.amount(6)`
**Used in:** 4 occurrences
- Specific test cases - no constant needed

---

## NFT Metadata Magic Numbers

### `Array(repeating: Data([9, 1, 6]), count: 5)`
**Used in:** 7 occurrences
- TokenRejectTransactionIntegrationTests.swift (5)
- TokenRejectFlowIntegrationTests.swift (2)

### `Array(repeating: Data([3, 6, 9]), count: 5)`
**Used in:** 2 occurrences
- TokenRejectTransactionIntegrationTests.swift

**Recommendation:** Replace ALL metadata arrays with the existing `TestConstants.testMetadata` (count: 10).

**Required Test Adjustments:**
Tests currently mint 5 NFTs and transfer/use serials [0], [1], etc. After switching to `testMetadata` (10 NFTs), the tests will mint 10 NFTs instead. The serial number usage in tests can remain the same since we're just minting more NFTs than before - tests that use serials 0-4 will still work fine with 10 minted NFTs.

**Files requiring metadata replacement:**
1. `TokenRejectTransactionIntegrationTests.swift` - 7 occurrences (5 with `[9,1,6]`, 2 with `[3,6,9]`)
2. `TokenRejectFlowIntegrationTests.swift` - 2 occurrences

**Changes needed:**
- Replace `.metadata(Array(repeating: Data([9, 1, 6]), count: 5))` → `.metadata(TestConstants.testMetadata)`
- Replace `.metadata(Array(repeating: Data([3, 6, 9]), count: 5))` → `.metadata(TestConstants.testMetadata)`
- No changes needed to serial number usage - tests using serials [0]-[4] will continue to work with 10 minted NFTs

---

## Account Configuration Magic Numbers

### `.maxAutomaticTokenAssociations(-1)` (unlimited)
**Used in:** 10 occurrences
- TokenAirdropTransactionIntegrationTests.swift (10)

**Recommendation:** Create `testUnlimitedTokenAssociations: Int32 = -1`

### `.maxAutomaticTokenAssociations(0)` (none)
**Used in:** 22 occurrences
- Multiple airdrop/claim/cancel test files

**Recommendation:** Create `testNoTokenAssociations: Int32 = 0`

### `.maxAutomaticTokenAssociations(100)`
**Used in:** 7 occurrences
- TokenRejectTransactionIntegrationTests.swift

**Recommendation:** Create `testManyTokenAssociations: Int32 = 100`

### `.maxAutomaticTokenAssociations(1)`
**Used in:** 1 occurrence
- AccountUpdateTransactionIntegrationTests.swift

**Recommendation:** Specific test case - no constant needed

---

## Initial Balance Magic Numbers

### `.initialBalance(Hbar(1))`
**Used in:** 17 occurrences
- Multiple schedule and account test files

**Recommendation:** Create `testSmallInitialBalance: Hbar = Hbar(1)`

### `.initialBalance(Hbar(10))`
**Used in:** 5 occurrences
- AccountAllowanceApproveTransactionIntegrationTests.swift (2)
- TopicCreateTransactionIntegrationTests.swift (1)
- ScheduleSignTransactionIntegrationTests.swift (1)
- ScheduleCreateTransactionIntegrationTests.swift (2)

**Recommendation:** Create `testMediumInitialBalance: Hbar = Hbar(10)`

---

## Assertion Magic Numbers

### `XCTAssertEqual(..., 0)`
**Used in:** Many occurrences for checking empty balances/counts
**Recommendation:** No constant needed - zero is semantically clear

### `XCTAssertEqual(..., 2)`
**Used in:** 6 occurrences for NFT counts
**Recommendation:** Specific to test scenarios - no constant needed

---

## Summary of Recommended New Constants

```swift
// Token configuration
public static let testTokenDecimals: UInt32 = 3
public static let testSmallInitialSupply: UInt64 = 10
public static let testMaxSupply: UInt64 = 5000

// Transfer amounts
public static let testTransferAmount: Int64 = 10        // For tokenTransfer (Int64)
public static let testOperationAmount: UInt64 = 10      // For burn/wipe/mint (UInt64)

// Token associations
public static let testUnlimitedTokenAssociations: Int32 = -1
public static let testNoTokenAssociations: Int32 = 0
public static let testManyTokenAssociations: Int32 = 100

// Account initial balances
public static let testSmallHbarBalance = Hbar(1)
public static let testMediumHbarBalance = Hbar(10)
```

**✅ IMPLEMENTED** - All constants above have been added to `TestConstants.swift` and all magic numbers have been replaced.

## NFT Metadata Consolidation

Instead of creating new metadata constants, use the existing `testMetadata` constant for ALL NFT minting operations:

**Existing constant:** `testMetadata = Array(repeating: Data([9, 1, 6]), count: 10)`

**Replace all of these:**
- `Array(repeating: Data([9, 1, 6]), count: 5)` → `TestConstants.testMetadata`
- `Array(repeating: Data([3, 6, 9]), count: 5)` → `TestConstants.testMetadata`

**Impact:** Tests will mint 10 NFTs instead of 5. Since tests only use a subset of the minted NFTs (typically serials 0-4), this change is backward compatible and requires no additional test logic changes.

## Notes

1. Some magic numbers (like 0 or 1) are intentionally used for specific test scenarios and don't benefit from constants.
2. The value `10` appears in multiple contexts (transfer amount, initial supply, burn amount) - consider whether one constant can serve all purposes or if context-specific constants are clearer.
3. Commented-out code in `TopicUpdateTransactionIntegrationTests.swift` and `BatchIntegrationTests.swift` was excluded from this audit.
4. NFT metadata arrays have been consolidated to use the single `testMetadata` constant rather than creating multiple variations.

