// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

/// Utility for extracting and transforming common JSON-RPC parameters into SDK-compatible types.
///
/// This enum provides static helper functions to convert raw JSON-RPC string values into
/// Hiero-specific domain types such as `AccountId`, `TokenId`, `Duration`, `Timestamp`, and numeric values.
/// These functions are used across multiple transaction parameter structs to streamline parsing logic.
///
/// - Note: All functions are stateless and safe to call independently. Most operate on optional input and
///         return `nil` if the input is `nil`.
///
/// Validation and range enforcement are delegated to the SDK or downstream logic.
internal enum CommonParamsParser {

    // MARK: - Entity Identifiers

    /// Parses an optional JSON-RPC string into an `AccountId`.
    ///
    /// - Parameters:
    ///   - param: A string representing an account ID, or `nil`.
    /// - Returns: An `AccountId` if the string is present and valid; otherwise `nil`.
    /// - Throws: If the account ID format is invalid.
    static internal func getAccountIdIfPresent(from param: String?) throws -> AccountId? {
        try param.flatMap { try AccountId.fromString($0) }
    }

    /// Parses an optional JSON-RPC string into a `FileId`.
    ///
    /// - Parameters:
    ///   - param: A string representing a file ID, or `nil`.
    /// - Returns: A `FileId` if the string is present and valid; otherwise `nil`.
    /// - Throws: If the file ID format is invalid.
    static internal func getFileIdIfPresent(from param: String?) throws -> FileId? {
        try param.flatMap { try FileId.fromString($0) }
    }

    /// Parses an optional JSON-RPC string into a `TokenId`.
    ///
    /// - Parameters:
    ///   - param: A string representing a token ID, or `nil`.
    /// - Returns: A `TokenId` if the string is present and valid; otherwise `nil`.
    /// - Throws: If the token ID format is invalid.
    static internal func getTokenIdIfPresent(from param: String?) throws -> TokenId? {
        try param.flatMap { try TokenId.fromString($0) }
    }

    /// Parses an optional JSON-RPC string into a `ContractId`.
    ///
    /// - Parameters:
    ///   - param: A string representing a contract ID, or `nil`.
    /// - Returns: A `ContractId` if the string is present and valid; otherwise `nil`.
    /// - Throws: If the contract ID format is invalid.
    static internal func getContractIdIfPresent(from param: String?) throws -> ContractId? {
        try param.flatMap { try ContractId.fromString($0) }
    }

    /// Parses an optional JSON-RPC list strings into `TokenIds`.
    ///
    /// - Parameters:
    ///   - param: An array of strings representing token IDs, or `nil`.
    /// - Returns: An array of `TokenId` values if present and valid; otherwise `nil`.
    /// - Throws: If any of the token ID strings are invalid.
    static internal func getTokenIdsIfPresent(from param: [String]?) throws -> [TokenId]? {
        try param?.map { try TokenId.fromString($0) }
    }

    // MARK: - Numeric Values

    /// Parses an optional JSON-RPC string into a `UInt64` amount.
    ///
    /// - Parameters:
    ///   - param: A string representing the amount, or `nil`.
    ///   - method: The JSON-RPC method name, used for error context.
    /// - Returns: A parsed `UInt64` value, or `nil` if the input is `nil`.
    /// - Throws: `JSONError.invalidParams` if the string is non-nil but not a valid integer.
    static internal func getAmountIfPresent(from param: String?, for method: JSONRPCMethod) throws -> UInt64? {
        try param.flatMap { try getAmount(from: $0, for: method, using: JSONRPCParam.parseUInt64(name:from:for:)) }
    }

    /// Parses a required JSON-RPC string into an amount, using the specified parsing function.
    ///
    /// This is a convenience wrapper that fixes the parameter name to `"amount"` so callers
    /// only need to supply the value, the JSON-RPC method name, and a parsing function.
    /// The parsing function can be any of the existing helpers (e.g., `parseInt64`,
    /// `parseUInt64ReinterpretingSigned`) or a custom closure with the matching signature.
    ///
    /// - Parameters:
    ///   - param: The raw string value of the `"amount"` parameter.
    ///   - method: The JSON-RPC method name, used for error reporting.
    ///   - parser: A function or closure that parses the parameter into the desired type.
    ///             It must accept `(name, value, method)` and return the parsed value or throw.
    /// - Returns: The parsed amount value of type `T`.
    /// - Throws: Any error thrown by the `parser`, such as `JSONError.invalidParams` for invalid inputs.
    static internal func getAmount<T>(
        from param: String,
        for method: JSONRPCMethod,
        using parser: (String, String, JSONRPCMethod) throws -> T
    ) rethrows -> T {
        try parser("amount", param, method)
    }

    /// Parses an optional JSON-RPC string into an `Hbar` initial balance.
    ///
    /// - Parameters:
    ///   - param: A string representing the initial balance in tinybars, or `nil`.
    ///   - method: The JSON-RPC method name, used for error context.
    /// - Returns: An `Hbar` value if the string is present and valid; otherwise `nil`.
    /// - Throws: `JSONError.invalidParams` if the string is non-nil but not a valid integer.
    static internal func getInitialBalanceIfPresent(from param: String?, for method: JSONRPCMethod) throws -> Hbar? {
        try param.flatMap {
            Hbar.fromTinybars(try JSONRPCParam.parseInt64(name: "initialBalance", from: $0, for: method))
        }
    }

    /// Parses an optional JSON-RPC string into an `Hbar` query payment and applies it to a query.
    ///
    /// - Parameters:
    ///   - param: A string representing the query payment in tinybars, or `nil`.
    ///   - query: The query to apply the payment amount to.
    ///   - method: The JSON-RPC method name, used for error context.
    /// - Throws: `JSONError.invalidParams` if the string is non-nil but not a valid integer.
    static internal func assignQueryPaymentIfPresent<Q: Query<R>, R>(
        from param: String?, to query: Q, for method: JSONRPCMethod
    ) throws {
        try param.ifPresent {
            query.paymentAmount(
                Hbar.fromTinybars(try JSONRPCParam.parseInt64(name: "queryPayment", from: $0, for: method)))
        }
    }

    /// Parses an optional JSON-RPC string into an `Hbar` max query payment.
    ///
    /// - Parameters:
    ///   - param: A string representing the max query payment in tinybars, or `nil`.
    ///   - method: The JSON-RPC method name, used for error context.
    /// - Returns: An `Hbar` value if the string is present and valid; otherwise `nil`.
    /// - Throws: `JSONError.invalidParams` if the string is non-nil but not a valid integer.
    static internal func getMaxQueryPaymentIfPresent(from param: String?, for method: JSONRPCMethod) throws -> Hbar? {
        try param.flatMap {
            Hbar.fromTinybars(try JSONRPCParam.parseInt64(name: "maxQueryPayment", from: $0, for: method))
        }
    }

    /// Parses a required JSON-RPC string into an `Int64` numerator.
    ///
    /// - Parameters:
    ///   - param: A non-optional string expected to represent an integer numerator.
    ///   - method: The name of the JSON-RPC method for contextual error reporting.
    /// - Returns: The parsed value as an `Int64`.
    /// - Throws: `JSONError.invalidParams` if the string cannot be parsed as a valid integer.
    static internal func getNumerator(from param: String, for method: JSONRPCMethod) throws -> Int64 {
        try JSONRPCParam.parseInt64(name: "numerator", from: param, for: method)
    }

    /// Parses a required JSON-RPC string into an `Int64` denominator.
    ///
    /// - Parameters:
    ///   - param: A non-optional string expected to represent an integer denominator.
    ///   - method: The name of the JSON-RPC method for contextual error reporting.
    /// - Returns: The parsed value as an `Int64`.
    /// - Throws: `JSONError.invalidParams` if the string cannot be parsed as a valid integer.
    static internal func getDenominator(from param: String, for method: JSONRPCMethod) throws -> Int64 {
        try JSONRPCParam.parseInt64(name: "denominator", from: param, for: method)
    }

    /// Parses a serial number string into a `UInt64`.
    ///
    /// The input string is parsed as a signed 64-bit integer (`Int64`) and its
    /// two’s-complement bit pattern is reinterpreted as an unsigned 64-bit integer (`UInt64`),
    /// for compatibility with SDK-level APIs.
    ///
    /// The optional `index` parameter is used only for error reporting. When serial numbers
    /// are provided as part of a list in a JSON-RPC request, including the index in error
    /// messages helps identify which element failed to parse (e.g. `"serial number[3]"`).
    ///
    /// - Parameters:
    ///   - param: The serial number string to parse.
    ///   - method: The JSON-RPC method name, used in error reporting.
    ///   - index: The position of this serial number in its list, if applicable (for error context).
    /// - Returns: The parsed serial number as a `UInt64`.
    /// - Throws: `JSONError.invalidParams` if the string is not a valid signed 64-bit integer.
    internal static func getSerialNumber(
        from param: String,
        for method: JSONRPCMethod,
        index: Int? = nil
    ) throws -> UInt64 {
        return try JSONRPCParam.parseUInt64ReinterpretingSigned(
            name: index.map { "serial number[\($0)]" } ?? "serial number",
            from: param,
            for: method)
    }

    // MARK: - Time Values

    /// Parses an optional JSON-RPC string into a `Duration` representing the auto-renew period.
    ///
    /// - Parameters:
    ///   - param: A string representing the auto-renew period in seconds, or `nil`.
    ///   - method: The JSON-RPC method name, used for contextual error reporting.
    /// - Returns: A `Duration` if the string is valid, or `nil` if `param` is `nil`.
    /// - Throws: `JSONError.invalidParams` if the string is not a valid integer.
    static internal func getAutoRenewPeriodIfPresent(from param: String?, for method: JSONRPCMethod) throws
        -> Duration?
    {
        try param.flatMap {
            Duration(
                seconds: try JSONRPCParam.parseUInt64ReinterpretingSigned(
                    name: "autoRenewPeriod",
                    from: $0,
                    for: method))
        }
    }

    /// Parses an optional JSON-RPC string into a `Timestamp` expiration time.
    ///
    /// Converts a string value into a `Timestamp` with second-level precision (sub-second nanos default to 0).
    ///
    /// - Parameters:
    ///   - param: An optional string expected to represent an integer timestamp in seconds.
    ///   - method: The name of the JSON-RPC method for contextual error reporting.
    /// - Returns: A `Timestamp` if the input is present and valid, or `nil` if the input is `nil`.
    /// - Throws: `JSONError.invalidParams` if the input string cannot be parsed as a valid integer.
    static internal func getExpirationTimeIfPresent(from param: String?, for method: JSONRPCMethod) throws
        -> Timestamp?
    {
        try param.flatMap {
            Timestamp(
                seconds: try JSONRPCParam.parseUInt64ReinterpretingSigned(
                    name: "expirationTime",
                    from: $0,
                    for: method),
                subSecondNanos: 0)
        }
    }

    // MARK: - Staking / Signing

    /// Parses an optional JSON-RPC string into a `UInt64` staked node ID.
    ///
    /// - Parameters:
    ///   - param: A string representing the node ID, or `nil`.
    ///   - method: The JSON-RPC method name, used for error context.
    /// - Returns: A `UInt64` if the string is present and valid; otherwise `nil`.
    /// - Throws: `JSONError.invalidParams` if the input is malformed.
    static internal func getStakedNodeIdIfPresent(from param: String?, for method: JSONRPCMethod) throws -> UInt64? {
        try param.flatMap {
            try JSONRPCParam.parseUInt64ReinterpretingSigned(name: "stakedNodeId", from: $0, for: method)
        }
    }

    /// Parses an optional JSON-RPC string into a `UInt64` gas value.
    ///
    /// - Parameters:
    ///   - param: A string representing the gas amount, or `nil`.
    ///   - method: The JSON-RPC method name, used for error context.
    /// - Returns: A `UInt64` if the string is present and valid; otherwise `nil`.
    /// - Throws: `JSONError.invalidParams` if the input is malformed.
    static internal func getGasIfPresent(from param: String?, for method: JSONRPCMethod) throws -> UInt64? {
        try param.flatMap {
            try JSONRPCParam.parseUInt64ReinterpretingSigned(name: "gas", from: $0, for: method)
        }
    }

    /// Parses an optional JSON-RPC string into a Hiero `Key`.
    ///
    /// - Parameters:
    ///   - param: A string representing the key, or `nil`.
    /// - Returns: A Hiero `Key` if the string is present and valid; otherwise `nil`.
    /// - Throws: If key parsing fails.
    static internal func getKeyIfPresent(from param: String?) throws -> Key? {
        try param.flatMap { try KeyService.getHieroKey(from: $0) }
    }

    /// Parses an optional JSON-RPC string array into a Hiero `KeyList`.
    ///
    /// - Parameters:
    ///   - param: An array of strings representing keys, or `nil`.
    /// - Returns: A Hiero `KeyList` if the array is present and all keys are valid; otherwise `nil`.
    /// - Throws: If any key parsing fails.
    static internal func getKeyListIfPresent(from param: [String]?) throws -> KeyList? {
        try param.map { try KeyList(keys: $0.map { try KeyService.getHieroKey(from: $0) }) }
    }

    // MARK: - Metadata

    /// Parses an optional JSON-RPC metadata string into a UTF-8 encoded `Data`.
    ///
    /// - Parameters:
    ///   - param: The optional `metadata` string provided in the JSON-RPC request.
    ///   - method: The JSON-RPC method name, used for contextual error messages.
    /// - Returns: The UTF-8 encoded `Data`, or `nil` if `param` was not provided.
    /// - Throws: `JSONError.invalidParams` if `param` is present but not valid UTF-8.
    static internal func getMetadataIfPresent(from param: String?, for method: JSONRPCMethod) throws -> Data? {
        try JSONRPCParam.parseUtf8DataIfPresent(name: "metadata", from: param, for: method)
    }

    // MARK: - Fees

    /// Converts a list of JSON-RPC `CustomFee` types into a list of Hiero `AnyCustomFee` types.
    ///
    /// Each input fee must specify **exactly one** fee type (`fixedFee`, `fractionalFee`, or `royaltyFee`).
    /// The function validates that constraint and translates string fields into SDK types, including:
    /// `AccountId`, `TokenId` (when present), and integer amounts/ratios. For fractional fees,
    /// the `assessmentMethod` must be `"inclusive"` or `"exclusive"`.
    ///
    /// If `param` is `nil`, this returns `nil` as well (i.e., “no custom fees provided”).
    ///
    /// - Parameters:
    ///   - param: The optional list of `CustomFee` entries from the JSON-RPC request.
    ///   - method: The JSON-RPC method name, used for contextual error messages during parsing.
    /// - Returns: An array of `AnyCustomFee` values suitable for Hiero APIs, or `nil`.
    /// - Throws:
    ///   - `JSONError.invalidParams` if a fee specifies zero or more than one fee type,
    ///     if `assessmentMethod` is not `"inclusive"`/`"exclusive"`, or if any numeric/string
    ///     field cannot be parsed (e.g., account IDs, token IDs, amounts, numerators/denominators).
    static internal func getHieroAnyCustomFeesIfPresent(from param: [CustomFee]?, for method: JSONRPCMethod) throws
        -> [AnyCustomFee]?
    {
        guard let customFees = param else { return nil }

        var anyCustomFees = [AnyCustomFee]()

        for customFee in customFees {
            let feeCollectorAccountId = try AccountId.fromString(customFee.feeCollectorAccountId)
            let feeCollectorsExempt = customFee.feeCollectorsExempt

            // Double-check exactly one fee type is present.
            let nonNilFees = [
                customFee.fixedFee as Any?, customFee.fractionalFee as Any?, customFee.royaltyFee as Any?,
            ].compactMap { $0 }
            guard nonNilFees.count == 1 else {
                throw JSONError.invalidParams(
                    "\(method): exactly one fee type (fixedFee, fractionalFee, or royaltyFee) SHALL be provided.")
            }

            if let fixed = customFee.fixedFee {
                anyCustomFees.append(
                    .fixed(
                        try getHieroFixedFee(
                            fixed,
                            feeCollectorAccountId: feeCollectorAccountId,
                            feeCollectorsExempt: feeCollectorsExempt,
                            for: method)))
            } else if let fractional = customFee.fractionalFee {
                guard fractional.assessmentMethod == "inclusive" || fractional.assessmentMethod == "exclusive"
                else {
                    throw JSONError.invalidParams(
                        "\(method.rawValue): assessmentMethod MUST be 'inclusive' or 'exclusive'.")
                }

                anyCustomFees.append(
                    .fractional(
                        Hiero.FractionalFee(
                            numerator: try getNumerator(from: fractional.numerator, for: method),
                            denominator: try getDenominator(
                                from: fractional.denominator,
                                for: method),
                            minimumAmount: try JSONRPCParam.parseUInt64ReinterpretingSigned(
                                name: "minimumAmount",
                                from: fractional.minimumAmount,
                                for: method),
                            maximumAmount: try JSONRPCParam.parseUInt64ReinterpretingSigned(
                                name: "maximumAmount",
                                from: fractional.maximumAmount,
                                for: method),
                            assessmentMethod: fractional.assessmentMethod == "inclusive"
                                ? Hiero.FractionalFee.FeeAssessmentMethod.inclusive
                                : Hiero.FractionalFee.FeeAssessmentMethod.exclusive,
                            feeCollectorAccountId: feeCollectorAccountId,
                            allCollectorsAreExempt: feeCollectorsExempt)))
            } else {
                // Safe to force unwrap since royalty is guaranteed to be non-nil at this point.
                anyCustomFees.append(
                    .royalty(
                        Hiero.RoyaltyFee(
                            numerator: try getNumerator(from: customFee.royaltyFee!.numerator, for: method),
                            denominator: try getDenominator(from: customFee.royaltyFee!.denominator, for: method),
                            fallbackFee: try customFee.royaltyFee!.fallbackFee.map {
                                try getHieroFixedFee(
                                    $0,
                                    feeCollectorAccountId: feeCollectorAccountId,
                                    feeCollectorsExempt: feeCollectorsExempt,
                                    for: method)
                            },
                            feeCollectorAccountId: feeCollectorAccountId,
                            allCollectorsAreExempt: feeCollectorsExempt
                        )))
            }
        }

        return anyCustomFees
    }

    /// Converts a JSON-RPC `FixedFee` types into a Hiero `FixedFee` type.
    ///
    /// This helper extracts and validates all fields from the JSON-RPC representation,
    /// including the fee amount and (optional) denominating token. It also attaches
    /// the specified fee collector and exemption flag to produce a valid SDK type.
    ///
    /// - Parameters:
    ///   - fee: The JSON-RPC `FixedFee` object to convert.
    ///   - feeCollectorAccountId: The `AccountId` of the account designated to collect this fee.
    ///   - feeCollectorsExempt: A flag indicating whether all collectors are exempt from paying the fee.
    ///   - method: The JSON-RPC method name, used for contextual error messages if parsing fails.
    /// - Returns: A fully-constructed `Hiero.FixedFee` ready for transaction execution.
    /// - Throws: `JSONError.invalidParams` if the `amount` or `denominatingTokenId` fields are invalid or malformed.
    static private func getHieroFixedFee(
        _ fee: FixedFee,
        feeCollectorAccountId: AccountId,
        feeCollectorsExempt: Bool,
        for method: JSONRPCMethod
    ) throws -> Hiero.FixedFee {
        return Hiero.FixedFee(
            amount: try getAmount(
                from: fee.amount,
                for: method,
                using: JSONRPCParam.parseUInt64ReinterpretingSigned(name:from:for:)),
            denominatingTokenId: try getTokenIdIfPresent(from: fee.denominatingTokenId),
            feeCollectorAccountId: feeCollectorAccountId,
            allCollectorsAreExempt: feeCollectorsExempt)
    }

    // MARK: - Topic

    /// Parses an optional JSON-RPC string into a `TopicId`.
    ///
    /// - Parameters:
    ///   - param: A string representing a topic ID, or `nil`.
    /// - Returns: A `TopicId` if the string is present and valid; otherwise `nil`.
    /// - Throws: If the topic ID format is invalid.
    static internal func getTopicIdIfPresent(from param: String?) throws -> TopicId? {
        try param.flatMap { try TopicId.fromString($0) }
    }

    /// Converts a list of JSON-RPC `CustomFee` types into a list of Hiero `CustomFixedFee` types for topics.
    ///
    /// Topics only support fixed fees, so this function extracts only the fixed fee portion
    /// of each custom fee entry. If a fee entry does not contain a fixed fee, it will throw an error.
    ///
    /// - Parameters:
    ///   - param: The optional list of `CustomFee` entries from the JSON-RPC request.
    ///   - method: The JSON-RPC method name, used for contextual error messages during parsing.
    /// - Returns: An array of `CustomFixedFee` values suitable for topic APIs, or `nil`.
    /// - Throws: `JSONError.invalidParams` if a fee does not contain a fixed fee or if any field cannot be parsed.
    static internal func getHieroCustomFixedFeesIfPresent(from param: [CustomFee]?, for method: JSONRPCMethod) throws
        -> [Hiero.CustomFixedFee]?
    {
        guard let customFees = param else { return nil }

        var fixedFees = [Hiero.CustomFixedFee]()

        for customFee in customFees {
            let feeCollectorAccountId = try AccountId.fromString(customFee.feeCollectorAccountId)
            let feeCollectorsExempt = customFee.feeCollectorsExempt

            guard let fixed = customFee.fixedFee else {
                throw JSONError.invalidParams(
                    "\(method): topics only support fixed fees.")
            }

            fixedFees.append(
                Hiero.CustomFixedFee(
                    try getHieroFixedFee(
                        fixed,
                        feeCollectorAccountId: feeCollectorAccountId,
                        feeCollectorsExempt: feeCollectorsExempt,
                        for: method),
                    feeCollectorAccountId,
                    feeCollectorsExempt))
        }

        return fixedFees
    }

    // MARK: - Airdrop

    /// Converts a list of `PendingAirdrop` types into a list of Hiero `PendingAirdropId` types.
    ///
    /// Each input airdrop may represent either:
    /// - A fungible token airdrop (identified by `tokenId` only), or
    /// - An NFT airdrop (identified by `tokenId` + one or more `serialNumbers`).
    ///
    /// The function parses the string identifiers into typed Hiero IDs (`AccountId`, `TokenId`,
    /// `NftId`) and constructs a matching set of `PendingAirdropId` objects.
    ///
    /// - Parameters:
    ///   - airdrops: The list of pending airdrop objects from a JSON-RPC request.
    ///   - method:   The JSON-RPC method being processed, used for contextual error messages.
    /// - Returns: An array of `PendingAirdropId` values corresponding to the input airdrops.
    /// - Throws:
    ///   - `HError` variants if any of the string IDs (`senderAccountId`, `receiverAccountId`,
    ///     `tokenId`) fail to parse into their typed counterparts.
    ///   - `JSONError.invalidParams` if an NFT serial number is invalid or cannot be parsed.
    static internal func pendingAirdropsToHieroPendingAirdropIds(
        _ airdrops: [PendingAirdrop],
        for method: JSONRPCMethod
    ) throws -> [PendingAirdropId] {
        var pendingAirdropIds = [PendingAirdropId]()
        for airdrop in airdrops {
            let senderAccountId = try AccountId.fromString(airdrop.senderAccountId)
            let receiverAccountId = try AccountId.fromString(airdrop.receiverAccountId)
            let tokenId = try TokenId.fromString(airdrop.tokenId)

            if let serialNumbers = airdrop.serialNumbers {
                for serial in serialNumbers {
                    let nftId = NftId(
                        tokenId: tokenId,
                        serial: try getSerialNumber(from: serial, for: method))
                    pendingAirdropIds.append(
                        PendingAirdropId(senderId: senderAccountId, receiverId: receiverAccountId, nftId: nftId))
                }
            } else {
                pendingAirdropIds.append(
                    PendingAirdropId(senderId: senderAccountId, receiverId: receiverAccountId, tokenId: tokenId))
            }
        }

        return pendingAirdropIds
    }

    // MARK: - File Contents

    /// Parses an optional JSON-RPC contents string into a UTF-8 encoded `Data`.
    ///
    /// - Parameters:
    ///   - param: The optional `contents` string provided in the JSON-RPC request.
    ///   - method: The JSON-RPC method name, used for contextual error messages.
    /// - Returns: The UTF-8 encoded `Data`, or `nil` if `param` was not provided.
    /// - Throws: `JSONError.invalidParams` if `param` is present but not valid UTF-8.
    static internal func getContentsIfPresent(from param: String?, for method: JSONRPCMethod) throws -> Data? {
        try JSONRPCParam.parseUtf8DataIfPresent(name: "contents", from: param, for: method)
    }

    // MARK: - Hex Data

    /// Parses an optional JSON-RPC hex string into `Data`.
    ///
    /// - Parameters:
    ///   - param: A hex-encoded string (with or without `0x` prefix), or `nil`.
    ///   - paramName: The name of the parameter for error messages.
    /// - Returns: The decoded `Data`, or `nil` if the input is `nil`.
    /// - Throws: `JSONError.internalError` if the hex string is invalid.
    static internal func parseHexToDataIfPresent(from param: String?, paramName: String) throws -> Data? {
        try param.flatMap {
            let hexString = $0.hasPrefix("0x") ? String($0.dropFirst(2)) : $0
            guard let data = hexStringToData(hexString) else {
                throw JSONError.internalError("\(paramName): invalid hex string")
            }
            return data
        }
    }

    /// Parses an optional JSON-RPC hex string into `Data` for function parameters.
    ///
    /// - Parameters:
    ///   - param: A hex-encoded string (with or without `0x` prefix), or `nil`.
    /// - Returns: The decoded `Data`, or `nil` if the input is `nil`.
    /// - Throws: `JSONError.internalError` if the hex string is invalid.
    static internal func getFunctionParametersIfPresent(from param: String?) throws -> Data? {
        try parseHexToDataIfPresent(from: param, paramName: "functionParameters")
    }

    /// Converts a hex string to Data.
    private static func hexStringToData(_ hex: String) -> Data? {
        let chars = Array(hex.utf8)
        guard chars.count % 2 == 0 else { return nil }

        var data = Data(capacity: chars.count / 2)
        for i in stride(from: 0, to: chars.count, by: 2) {
            guard let high = hexValue(chars[i]), let low = hexValue(chars[i + 1]) else {
                return nil
            }
            data.append(high << 4 | low)
        }
        return data
    }

    /// Returns the numeric value of a hex character, or nil if invalid.
    private static func hexValue(_ char: UInt8) -> UInt8? {
        switch char {
        case 0x30...0x39: return char - 0x30  // '0'-'9'
        case 0x41...0x46: return char - 0x41 + 10  // 'A'-'F'
        case 0x61...0x66: return char - 0x61 + 10  // 'a'-'f'
        default: return nil
        }
    }
}
