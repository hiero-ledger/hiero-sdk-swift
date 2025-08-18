// SPDX-License-Identifier: Apache-2.0

/// Represents an HBAR allowance granted from an owner to a spender.
///
/// This struct encapsulates the `amount` of HBAR authorized for transfer.
/// It is initialized from a parsed JSON-RPC parameters dictionary, and
/// expects the `"amount"` field to be present.
internal struct HbarAllowance {

    internal var amount: String

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.amount = try JSONRPCParser.getRequiredParameter(name: "amount", from: params, for: method)
    }
}
