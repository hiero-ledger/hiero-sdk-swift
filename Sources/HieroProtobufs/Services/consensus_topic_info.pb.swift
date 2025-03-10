// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: consensus_topic_info.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

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
/// Current state of a topic.
public struct Proto_ConsensusTopicInfo: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///*
  /// The memo associated with the topic (UTF-8 encoding max 100 bytes)
  public var memo: String = String()

  ///*
  /// When a topic is created, its running hash is initialized to 48 bytes of binary zeros.
  /// For each submitted message, the topic's running hash is then updated to the output
  /// of a particular SHA-384 digest whose input data include the previous running hash.
  /// 
  /// See the TransactionReceipt.proto documentation for an exact description of the
  /// data included in the SHA-384 digest used for the update.
  public var runningHash: Data = Data()

  ///*
  /// Sequence number (starting at 1 for the first submitMessage) of messages on the topic.
  public var sequenceNumber: UInt64 = 0

  ///*
  /// Effective consensus timestamp at (and after) which submitMessage calls will no longer succeed on the topic
  /// and the topic will expire and after AUTORENEW_GRACE_PERIOD be automatically deleted.
  public var expirationTime: Proto_Timestamp {
    get {return _expirationTime ?? Proto_Timestamp()}
    set {_expirationTime = newValue}
  }
  /// Returns true if `expirationTime` has been explicitly set.
  public var hasExpirationTime: Bool {return self._expirationTime != nil}
  /// Clears the value of `expirationTime`. Subsequent reads from it will return its default value.
  public mutating func clearExpirationTime() {self._expirationTime = nil}

  ///*
  /// Access control for update/delete of the topic. Null if there is no key.
  public var adminKey: Proto_Key {
    get {return _adminKey ?? Proto_Key()}
    set {_adminKey = newValue}
  }
  /// Returns true if `adminKey` has been explicitly set.
  public var hasAdminKey: Bool {return self._adminKey != nil}
  /// Clears the value of `adminKey`. Subsequent reads from it will return its default value.
  public mutating func clearAdminKey() {self._adminKey = nil}

  ///*
  /// Access control for ConsensusService.submitMessage. Null if there is no key.
  public var submitKey: Proto_Key {
    get {return _submitKey ?? Proto_Key()}
    set {_submitKey = newValue}
  }
  /// Returns true if `submitKey` has been explicitly set.
  public var hasSubmitKey: Bool {return self._submitKey != nil}
  /// Clears the value of `submitKey`. Subsequent reads from it will return its default value.
  public mutating func clearSubmitKey() {self._submitKey = nil}

  ///*
  /// If an auto-renew account is specified, when the topic expires, its lifetime will be extended
  /// by up to this duration (depending on the solvency of the auto-renew account). If the
  /// auto-renew account has no funds at all, the topic will be deleted instead.
  public var autoRenewPeriod: Proto_Duration {
    get {return _autoRenewPeriod ?? Proto_Duration()}
    set {_autoRenewPeriod = newValue}
  }
  /// Returns true if `autoRenewPeriod` has been explicitly set.
  public var hasAutoRenewPeriod: Bool {return self._autoRenewPeriod != nil}
  /// Clears the value of `autoRenewPeriod`. Subsequent reads from it will return its default value.
  public mutating func clearAutoRenewPeriod() {self._autoRenewPeriod = nil}

  ///*
  /// The account, if any, to charge for automatic renewal of the topic's lifetime upon expiry.
  public var autoRenewAccount: Proto_AccountID {
    get {return _autoRenewAccount ?? Proto_AccountID()}
    set {_autoRenewAccount = newValue}
  }
  /// Returns true if `autoRenewAccount` has been explicitly set.
  public var hasAutoRenewAccount: Bool {return self._autoRenewAccount != nil}
  /// Clears the value of `autoRenewAccount`. Subsequent reads from it will return its default value.
  public mutating func clearAutoRenewAccount() {self._autoRenewAccount = nil}

  ///*
  /// The ledger ID the response was returned from; please see <a href="https://github.com/hashgraph/hedera-improvement-proposal/blob/master/HIP/hip-198.md">HIP-198</a> for the network-specific IDs. 
  public var ledgerID: Data = Data()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _expirationTime: Proto_Timestamp? = nil
  fileprivate var _adminKey: Proto_Key? = nil
  fileprivate var _submitKey: Proto_Key? = nil
  fileprivate var _autoRenewPeriod: Proto_Duration? = nil
  fileprivate var _autoRenewAccount: Proto_AccountID? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "proto"

extension Proto_ConsensusTopicInfo: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ConsensusTopicInfo"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "memo"),
    2: .same(proto: "runningHash"),
    3: .same(proto: "sequenceNumber"),
    4: .same(proto: "expirationTime"),
    5: .same(proto: "adminKey"),
    6: .same(proto: "submitKey"),
    7: .same(proto: "autoRenewPeriod"),
    8: .same(proto: "autoRenewAccount"),
    9: .standard(proto: "ledger_id"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.memo) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.runningHash) }()
      case 3: try { try decoder.decodeSingularUInt64Field(value: &self.sequenceNumber) }()
      case 4: try { try decoder.decodeSingularMessageField(value: &self._expirationTime) }()
      case 5: try { try decoder.decodeSingularMessageField(value: &self._adminKey) }()
      case 6: try { try decoder.decodeSingularMessageField(value: &self._submitKey) }()
      case 7: try { try decoder.decodeSingularMessageField(value: &self._autoRenewPeriod) }()
      case 8: try { try decoder.decodeSingularMessageField(value: &self._autoRenewAccount) }()
      case 9: try { try decoder.decodeSingularBytesField(value: &self.ledgerID) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if !self.memo.isEmpty {
      try visitor.visitSingularStringField(value: self.memo, fieldNumber: 1)
    }
    if !self.runningHash.isEmpty {
      try visitor.visitSingularBytesField(value: self.runningHash, fieldNumber: 2)
    }
    if self.sequenceNumber != 0 {
      try visitor.visitSingularUInt64Field(value: self.sequenceNumber, fieldNumber: 3)
    }
    try { if let v = self._expirationTime {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
    } }()
    try { if let v = self._adminKey {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
    } }()
    try { if let v = self._submitKey {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 6)
    } }()
    try { if let v = self._autoRenewPeriod {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 7)
    } }()
    try { if let v = self._autoRenewAccount {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 8)
    } }()
    if !self.ledgerID.isEmpty {
      try visitor.visitSingularBytesField(value: self.ledgerID, fieldNumber: 9)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_ConsensusTopicInfo, rhs: Proto_ConsensusTopicInfo) -> Bool {
    if lhs.memo != rhs.memo {return false}
    if lhs.runningHash != rhs.runningHash {return false}
    if lhs.sequenceNumber != rhs.sequenceNumber {return false}
    if lhs._expirationTime != rhs._expirationTime {return false}
    if lhs._adminKey != rhs._adminKey {return false}
    if lhs._submitKey != rhs._submitKey {return false}
    if lhs._autoRenewPeriod != rhs._autoRenewPeriod {return false}
    if lhs._autoRenewAccount != rhs._autoRenewAccount {return false}
    if lhs.ledgerID != rhs.ledgerID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
