// SPDX-License-Identifier: Apache-2.0

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.6)
    #error("Hiero SDK doesn't support Swift versions below 5.6.")
#endif

// Deprecation warning for Swift 5.x users.
#if swift(>=5.6) && swift(<6.0)
    #warning(
        "Swift 5.x support is deprecated and will be removed in a future release. Please migrate to Swift 6.0+. See https://github.com/hiero-ledger/hiero-sdk-swift for details."
    )
#endif
