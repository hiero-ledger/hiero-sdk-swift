// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: services/token_mint.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

///*
/// # Token Mint
/// Mint new tokens and deliver them to the token treasury. This is akin
/// to how a fiat treasury will mint new coinage for circulation.
///
/// ### Keywords
/// The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
/// "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
/// document are to be interpreted as described in
/// [RFC2119](https://www.ietf.org/rfc/rfc2119) and clarified in
/// [RFC8174](https://www.ietf.org/rfc/rfc8174).

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

///*
/// Mint tokens and deliver the new tokens to the token treasury account.
///
/// The token MUST have a `supply_key` set and that key MUST NOT
/// be an empty `KeyList`.<br/>
/// The token `supply_key` MUST sign this transaction.<br/>
/// This operation SHALL increase the total supply for the token type by
/// the number of tokens "minted".<br/>
/// The total supply for the token type MUST NOT be increased above the
/// maximum supply limit (2^63-1) by this transaction.<br/>
/// The tokens minted SHALL be credited to the token treasury account.<br/>
/// If the token is a fungible/common type, the amount MUST be specified.<br/>
/// If the token is a non-fungible/unique type, the metadata bytes for each
/// unique token MUST be specified in the `metadata` list.<br/>
/// Each unique metadata MUST not exceed the global metadata size limit defined
/// by the network configuration value `tokens.maxMetadataBytes`.<br/>
/// The global batch size limit (`tokens.nfts.maxBatchSizeMint`) SHALL set
/// the maximum number of individual NFT metadata permitted in a single
/// `tokenMint` transaction.
///
/// ### Block Stream Effects
/// None
public struct Proto_TokenMintTransactionBody: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///*
  /// A token identifier.
  /// <p>
  /// This SHALL identify the token type to "mint".<br/>
  /// The identified token MUST exist, and MUST NOT be deleted.
  public var token: Proto_TokenID {
    get {return _token ?? Proto_TokenID()}
    set {_token = newValue}
  }
  /// Returns true if `token` has been explicitly set.
  public var hasToken: Bool {return self._token != nil}
  /// Clears the value of `token`. Subsequent reads from it will return its default value.
  public mutating func clearToken() {self._token = nil}

  ///*
  /// An amount to mint to the Treasury Account.
  /// <p>
  /// This is interpreted as an amount in the smallest possible denomination
  /// for the token (10<sup>-decimals</sup> whole tokens).<br/>
  /// The balance for the token treasury account SHALL receive the newly
  /// minted tokens.<br/>
  /// If this value is equal to zero (`0`), the token SHOULD be a
  /// non-fungible/unique type.<br/>
  /// If this value is non-zero, the token MUST be a fungible/common type.
  public var amount: UInt64 = 0

  ///*
  /// A list of metadata bytes.<br/>
  /// <p>
  /// One non-fungible/unique token SHALL be minted for each entry
  /// in this list.<br/>
  /// Each entry in this list MUST NOT be larger than the limit set by the
  /// current network configuration value `tokens.maxMetadataBytes`.<br/>
  /// This list MUST NOT contain more entries than the current limit set by
  /// the network configuration value `tokens.nfts.maxBatchSizeMint`.<br/>
  /// If this list is not empty, the token MUST be a
  /// non-fungible/unique type.<br/>
  /// If this list is empty, the token MUST be a fungible/common type.
  public var metadata: [Data] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _token: Proto_TokenID? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "proto"

extension Proto_TokenMintTransactionBody: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".TokenMintTransactionBody"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "token"),
    2: .same(proto: "amount"),
    3: .same(proto: "metadata"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._token) }()
      case 2: try { try decoder.decodeSingularUInt64Field(value: &self.amount) }()
      case 3: try { try decoder.decodeRepeatedBytesField(value: &self.metadata) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._token {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    if self.amount != 0 {
      try visitor.visitSingularUInt64Field(value: self.amount, fieldNumber: 2)
    }
    if !self.metadata.isEmpty {
      try visitor.visitRepeatedBytesField(value: self.metadata, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_TokenMintTransactionBody, rhs: Proto_TokenMintTransactionBody) -> Bool {
    if lhs._token != rhs._token {return false}
    if lhs.amount != rhs.amount {return false}
    if lhs.metadata != rhs.metadata {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
