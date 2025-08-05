// SPDX-License-Identifier: Apache-2.0

/// Represents the expected parameters for the `reset` JSON-RPC method.
///
/// The `reset` method does not require any parameters, so this struct is intentionally empty.
/// Used for strict type validation when handling JSON-RPC requests.
internal struct ResetParams {

    internal init(request: JSONRequest) {
    }
}
