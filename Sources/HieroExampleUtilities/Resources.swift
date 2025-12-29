// SPDX-License-Identifier: Apache-2.0

import Foundation

private struct ContractJson: Decodable {
    private let object: String?
    private let bytecode: String?

    fileprivate var bytecodeHex: String {
        (object ?? bytecode)!
    }
}

public enum Resources {
    /// The "big contents" used in `ConsensusPubSubChunked` and `FileAppendChunked`.
    public static var bigContents: String {
        let url = Bundle.module.url(forResource: "big-contents", withExtension: "txt")!
        // swiftlint:disable:next force_try
        let data = try! Data(contentsOf: url)
        return String(data: data, encoding: .utf8)!
    }

    /// Bytecode for the simple contract example.
    public static var simpleContract: String {
        let url = Bundle.module.url(forResource: "hello-world", withExtension: "json")!
        // swiftlint:disable:next force_try
        let json = try! JSONDecoder().decode(ContractJson.self, from: Data(contentsOf: url))
        return json.bytecodeHex
    }

    /// Bytecode for the stateful contract example.
    public static var statefulContract: String {
        let url = Bundle.module.url(forResource: "stateful", withExtension: "json")!
        // swiftlint:disable:next force_try
        let json = try! JSONDecoder().decode(ContractJson.self, from: Data(contentsOf: url))
        return json.bytecodeHex
    }
}
