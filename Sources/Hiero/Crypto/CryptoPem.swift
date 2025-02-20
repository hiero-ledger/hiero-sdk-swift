import Foundation

extension Crypto {
    internal enum Pem {}
}

extension Crypto.Pem {
    private static func isValidLabelCharacter(_ char: Character) -> Bool {
        let visibleAscii: ClosedRange<UInt8> = 0x21...0x7e
        let hyphenMinus: Character = "-"

        return char != hyphenMinus && (char.asciiValue.map(visibleAscii.contains)) ?? false
    }

    private static let endOfLabel: String = "-----"
    private static let beginLabel: String = "-----BEGIN "
    private static let endLabel: String = "-----END "

    internal struct Document {
        internal let typeLabel: String
        internal let headers: [String: String]
        internal let der: Data
    }

    private static func parseTypeLabel(of message: inout ArraySlice<Substring>) throws -> Substring {
        guard let (typeLabel, rest) = message.splitFirst(),
            let typeLabel = typeLabel.stripPrefix(beginLabel),
            let typeLabel = typeLabel.stripSuffix(endOfLabel)
        else {
            throw HError.keyParse("Invalid Pem")
        }

        guard typeLabel.allSatisfy({ isValidLabelCharacter($0) || $0 == " " }), typeLabel.last != " " else {
            throw HError.keyParse("Invalid Pem")
        }

        message = rest

        return typeLabel
    }

    private static func parseEnd(of message: inout ArraySlice<Substring>, typeLabel: Substring) throws {
        guard let (end, rest) = message.splitLast(),
            let end = end.stripPrefix(endLabel),
            let end = end.stripSuffix(endOfLabel),
            typeLabel == end
        else {
            throw HError.keyParse("Invalid Pem")
        }

        message = rest
    }

    private static func parseHeaders(of message: inout ArraySlice<Substring>) throws -> [String: String]? {
        // note this isn't technically compliant with the RFC where pem headers are valid, but that RFC is also superceeded and pem headers shouldn't exist anymore :/
        guard let splitIndex = message.firstIndex(of: "") else {
            return nil
        }

        var headers: [String: String] = [:]

        for line in message[..<splitIndex] {
            guard let (k, v) = line.splitOnce(on: ":") else {
                throw HError.keyParse("Invalid Pem")
            }

            let key = k.trimmingCharacters(in: .whitespaces)
            let value = v.trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }

        message = message[message.index(after: splitIndex)...]

        return headers
    }

    // todo: use data instead of string
    internal static func decode(_ message: String) throws -> Document {
        let fullMessage = message.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        var message = fullMessage[...]

        let typeLabel = try parseTypeLabel(of: &message)
        try parseEnd(of: &message, typeLabel: typeLabel)

        let headers = try parseHeaders(of: &message) ?? [:]

        let (base64Final, base64Lines) = message.splitLast() ?? ("", [])

        var base64Message: String = ""

        for line in base64Lines {
            guard line.count == 64 else {
                throw HError.keyParse("Invalid Pem")
            }

            base64Message += line
        }

        guard base64Final.count <= 64 else {
            throw HError.keyParse("Invalid Pem")
        }

        base64Message += base64Final

        // fixme: ensure that `+/` are the characterset used.
        guard let message = Data(base64Encoded: base64Message) else {
            throw HError.keyParse("Invalid Pem")
        }

        return Document(typeLabel: String(typeLabel), headers: headers, der: message)
    }
}
