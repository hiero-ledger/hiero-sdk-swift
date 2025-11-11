// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - PEM (Privacy Enhanced Mail) Format
//
// PEM is a text-based encoding format for cryptographic keys and certificates.
// It uses Base64 encoding wrapped with "-----BEGIN/END-----" markers.
//
// This implementation parses PEM-encoded private keys used by the Hiero SDK.

extension CryptoNamespace {
    /// PEM (Privacy Enhanced Mail) format parser for cryptographic keys.
    ///
    /// PEM format consists of:
    /// ```
    /// -----BEGIN <TYPE LABEL>-----
    /// <Base64-encoded data>
    /// -----END <TYPE LABEL>-----
    /// ```
    ///
    /// Common type labels include:
    /// - `PRIVATE KEY` (PKCS#8 unencrypted)
    /// - `ENCRYPTED PRIVATE KEY` (PKCS#8 encrypted)
    /// - `EC PRIVATE KEY` (SEC1 format)
    internal enum Pem {}
}

extension CryptoNamespace.Pem {
    private static func isValidLabelCharacter(_ char: Character) -> Bool {
        let visibleAscii: ClosedRange<UInt8> = 0x21...0x7e
        let hyphenMinus: Character = "-"

        return char != hyphenMinus && (char.asciiValue.map(visibleAscii.contains)) ?? false
    }

    private static let endOfLabel: String = "-----"
    private static let beginLabel: String = "-----BEGIN "
    private static let endLabel: String = "-----END "

    /// A parsed PEM document containing the decoded key data.
    internal struct Document {
        /// The type label from the PEM header (e.g., "PRIVATE KEY").
        internal let typeLabel: String

        /// Optional headers from the PEM document (rarely used).
        internal let headers: [String: String]

        /// The decoded DER (Distinguished Encoding Rules) data.
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

    /// Parse a PEM-encoded string into a structured document.
    ///
    /// - Parameter message: The PEM-formatted string to parse.
    /// - Returns: A `Document` containing the parsed type label, headers, and DER-encoded data.
    /// - Throws: `HError.keyParse` if the PEM format is invalid.
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
