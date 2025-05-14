// SPDX-License-Identifier: Apache-2.0

public final class MirrorNodeContractEstimateGasQuery: MirrorNodeContractQuery {

    public override init() {
    }

    internal override func getEstimate() -> Bool {
        return true
    }
}
