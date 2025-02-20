import Foundation

private struct ContractJson: Decodable {
    private let object: String?
    private let bytecode: String?

    fileprivate var bytecodeHex: String {
        (object ?? bytecode)!
    }
}

public enum Resources {
    private static func getData(forUrl url: URL) async throws -> Data {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            // this version is different than the one above (this one has a `delegate: nil`), confusing I know
            return try await URLSession.shared.data(from: url, delegate: nil).0
        }

        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, let _ = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: data)
            }

            task.resume()
        }
    }

    private static func bytecode(forUrl url: URL) async throws -> String {
        try await JSONDecoder().decode(ContractJson.self, from: getData(forUrl: url)).bytecodeHex
    }

    /// The "big contents" used in `ConsensusPubSubChunked` and `FileAppendChunked`.
    public static var bigContents: String {
        get async throws {
            // this is indeed, the way this is expected to be done :/
            let url = Bundle.module.url(forResource: "big-contents", withExtension: "txt")!
            return try await String(data: getData(forUrl: url), encoding: .utf8)!
        }
    }

    /// Bytecode for the simple contract example.
    public static var simpleContract: String {
        get async throws {
            let url = Bundle.module.url(forResource: "hello-world", withExtension: "json")!

            return try await bytecode(forUrl: url)
        }
    }

    /// Bytecode for the stateful contract example.
    public static var statefulContract: String {
        get async throws {
            let url = Bundle.module.url(forResource: "stateful", withExtension: "json")!

            return try await bytecode(forUrl: url)
        }
    }
}
