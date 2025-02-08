// SPDX-License-Identifier: Apache-2.0

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.6)
    #error("Hedera SDK doesn't support Swift versions below 5.6.")
#endif
