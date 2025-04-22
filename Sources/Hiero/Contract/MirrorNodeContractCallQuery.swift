// SPDX-License-Identifier: Apache-2.0

public final class MirrorNodeContractCallQuery: MirrorNodeContractQuery {

    public override init() {
    }

    internal override func getEstimate() -> Bool {
        return false
    }
}
