// SPDX-License-Identifier: Apache-2.0

// MARK: - PEM Format Parser

/// PEM (Privacy Enhanced Mail) is a text-based encoding format for cryptographic
/// keys and certificates. It uses Base64 encoding wrapped with header/footer markers.
///
/// Format:
/// ```
/// -----BEGIN <TYPE LABEL>-----
/// <Base64-encoded DER data>
/// -----END <TYPE LABEL>-----
/// ```
///
/// Common type labels:
/// - "PRIVATE KEY" (PKCS#8 unencrypted)
/// - "ENCRYPTED PRIVATE KEY" (PKCS#8 encrypted)
/// - "EC PRIVATE KEY" (SEC1 format)
/// - "PUBLIC KEY" (SubjectPublicKeyInfo)

import Foundation

/// PEM (Privacy Enhanced Mail) format parser for cryptographic keys.
///
/// This parser handles PEM-encoded private keys used by the Hiero SDK,
/// extracting the DER-encoded data for further processing.
///
/// ## Example
/// ```swift
/// let document = try Pem.decode(pemString)
/// print(document.typeLabel)  // "PRIVATE KEY"
/// // Use document.der for further parsing
/// ```
internal enum Pem {

    // MARK: - Document Type

    /// A parsed PEM document containing the decoded key data.
    ///
    /// After parsing a PEM string, this struct contains:
    /// - The type label identifying the content type
    /// - Any optional headers (rarely used in modern PEM)
    /// - The raw DER-encoded binary data
    internal struct Document {
        /// The type label from the PEM header.
        ///
        /// Common values:
        /// - `"PRIVATE KEY"` - PKCS#8 unencrypted private key
        /// - `"ENCRYPTED PRIVATE KEY"` - PKCS#8 encrypted private key
        /// - `"EC PRIVATE KEY"` - SEC1 elliptic curve private key
        internal let typeLabel: String

        /// Optional headers from the PEM document.
        ///
        /// Headers are key-value pairs that appear between the BEGIN line
        /// and the Base64 data. They are rarely used in modern PEM files.
        internal let headers: [String: String]

        /// The decoded DER (Distinguished Encoding Rules) data.
        ///
        /// This is the binary ASN.1 data that was Base64-encoded in the PEM file.
        /// It can be parsed according to its type (PKCS#8, SEC1, etc.).
        internal let der: Data
    }

    // MARK: - Public API

    /// Parse a PEM-encoded string into a structured document.
    ///
    /// This method validates the PEM format and extracts:
    /// 1. The type label from the BEGIN/END markers
    /// 2. Any optional headers
    /// 3. The Base64-decoded DER data
    ///
    /// ## Example
    /// ```swift
    /// let pem = """
    ///     -----BEGIN PRIVATE KEY-----
    ///     MIGHAgEAMB...
    ///     -----END PRIVATE KEY-----
    ///     """
    /// let document = try Pem.decode(pem)
    /// print(document.typeLabel)  // "PRIVATE KEY"
    /// // Use document.der for further parsing
    /// ```
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

    // MARK: - Private Constants

    /// The "-----" delimiter that ends the type label
    private static let endOfLabel: String = "-----"

    /// The "-----BEGIN " prefix that starts a PEM document
    private static let beginLabel: String = "-----BEGIN "

    /// The "-----END " prefix that ends a PEM document
    private static let endLabel: String = "-----END "

    // MARK: - Private Parsing Helpers

    /// Check if a character is valid in a PEM type label.
    ///
    /// Per RFC 7468, valid label characters are printable ASCII (0x21-0x7E)
    /// excluding hyphen-minus, which is used as the delimiter.
    ///
    /// - Parameter char: The character to validate.
    /// - Returns: `true` if the character is valid in a type label.
    private static func isValidLabelCharacter(_ char: Character) -> Bool {
        let visibleAscii: ClosedRange<UInt8> = 0x21...0x7e
        let hyphenMinus: Character = "-"

        return char != hyphenMinus && (char.asciiValue.map(visibleAscii.contains)) ?? false
    }

    /// Parse and extract the type label from the BEGIN line.
    ///
    /// Extracts the label from `-----BEGIN <LABEL>-----` and validates that
    /// all characters are valid label characters.
    ///
    /// - Parameter message: The message lines (mutated to remove the BEGIN line).
    /// - Returns: The extracted type label (e.g., "PRIVATE KEY").
    /// - Throws: `HError.keyParse` if the BEGIN line is missing or malformed.
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

    /// Parse and validate the END line matches the BEGIN line.
    ///
    /// Verifies that the END line exists and its label matches the BEGIN label.
    /// The END line is expected to be at the end of the message.
    ///
    /// - Parameters:
    ///   - message: The message lines (mutated to remove the END line).
    ///   - typeLabel: The expected type label from the BEGIN line.
    /// - Throws: `HError.keyParse` if the END line is missing or doesn't match.
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

    /// Parse optional headers from the PEM document.
    ///
    /// Headers are `Key: Value` pairs that appear between the BEGIN line
    /// and the Base64 data, separated by an empty line. Modern PEM files
    /// rarely use headers, but they're supported for compatibility.
    ///
    /// - Parameter message: The message lines (mutated to remove header lines).
    /// - Returns: A dictionary of headers, or `nil` if no headers present.
    /// - Throws: `HError.keyParse` if a header line is malformed.
    private static func parseHeaders(of message: inout ArraySlice<Substring>) throws -> [String: String]? {
        // Note: This isn't fully RFC-compliant for legacy PEM headers,
        // but those are obsolete per RFC 7468.
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
}
