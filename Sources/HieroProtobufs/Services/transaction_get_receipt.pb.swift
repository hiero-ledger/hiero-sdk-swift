// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: transaction_get_receipt.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

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
/// Get the receipt of a transaction, given its transaction ID. Once a transaction reaches consensus,
/// then information about whether it succeeded or failed will be available until the end of the
/// receipt period.  Before and after the receipt period, and for a transaction that was never
/// submitted, the receipt is unknown.  This query is free (the payment field is left empty). No
/// State proof is available for this response
public struct Proto_TransactionGetReceiptQuery: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///*
  /// Standard info sent from client to node, including the signed payment, and what kind of
  /// response is requested (cost, state proof, both, or neither).
  public var header: Proto_QueryHeader {
    get {return _header ?? Proto_QueryHeader()}
    set {_header = newValue}
  }
  /// Returns true if `header` has been explicitly set.
  public var hasHeader: Bool {return self._header != nil}
  /// Clears the value of `header`. Subsequent reads from it will return its default value.
  public mutating func clearHeader() {self._header = nil}

  ///*
  /// The ID of the transaction for which the receipt is requested.
  public var transactionID: Proto_TransactionID {
    get {return _transactionID ?? Proto_TransactionID()}
    set {_transactionID = newValue}
  }
  /// Returns true if `transactionID` has been explicitly set.
  public var hasTransactionID: Bool {return self._transactionID != nil}
  /// Clears the value of `transactionID`. Subsequent reads from it will return its default value.
  public mutating func clearTransactionID() {self._transactionID = nil}

  ///*
  /// Whether receipts of processing duplicate transactions should be returned along with the
  /// receipt of processing the first consensus transaction with the given id whose status was
  /// neither <tt>INVALID_NODE_ACCOUNT</tt> nor <tt>INVALID_PAYER_SIGNATURE</tt>; <b>or</b>, if no
  /// such receipt exists, the receipt of processing the first transaction to reach consensus with
  /// the given transaction id.
  public var includeDuplicates: Bool = false

  ///*
  /// Whether the response should include the receipts of any child transactions spawned by the 
  /// top-level transaction with the given transactionID. 
  public var includeChildReceipts: Bool = false

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _header: Proto_QueryHeader? = nil
  fileprivate var _transactionID: Proto_TransactionID? = nil
}

///*
/// Response when the client sends the node TransactionGetReceiptQuery. If it created a new entity
/// (account, file, or smart contract instance) then one of the three ID fields will be filled in
/// with the ID of the new entity. Sometimes a single transaction will create more than one new
/// entity, such as when a new contract instance is created, and this also creates the new account
/// that it owned by that instance. No State proof is available for this response
public struct Proto_TransactionGetReceiptResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///*
  /// Standard response from node to client, including the requested fields: cost, or state proof,
  /// or both, or neither
  public var header: Proto_ResponseHeader {
    get {return _header ?? Proto_ResponseHeader()}
    set {_header = newValue}
  }
  /// Returns true if `header` has been explicitly set.
  public var hasHeader: Bool {return self._header != nil}
  /// Clears the value of `header`. Subsequent reads from it will return its default value.
  public mutating func clearHeader() {self._header = nil}

  ///*
  /// Either the receipt of processing the first consensus transaction with the given id whose
  /// status was neither <tt>INVALID_NODE_ACCOUNT</tt> nor <tt>INVALID_PAYER_SIGNATURE</tt>;
  /// <b>or</b>, if no such receipt exists, the receipt of processing the first transaction to
  /// reach consensus with the given transaction id.
  public var receipt: Proto_TransactionReceipt {
    get {return _receipt ?? Proto_TransactionReceipt()}
    set {_receipt = newValue}
  }
  /// Returns true if `receipt` has been explicitly set.
  public var hasReceipt: Bool {return self._receipt != nil}
  /// Clears the value of `receipt`. Subsequent reads from it will return its default value.
  public mutating func clearReceipt() {self._receipt = nil}

  ///*
  /// The receipts of processing all transactions with the given id, in consensus time order.
  public var duplicateTransactionReceipts: [Proto_TransactionReceipt] = []

  ///*
  /// The receipts (if any) of all child transactions spawned by the transaction with the 
  /// given top-level id, in consensus order. Always empty if the top-level status is UNKNOWN.
  public var childTransactionReceipts: [Proto_TransactionReceipt] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _header: Proto_ResponseHeader? = nil
  fileprivate var _receipt: Proto_TransactionReceipt? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "proto"

extension Proto_TransactionGetReceiptQuery: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".TransactionGetReceiptQuery"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "header"),
    2: .same(proto: "transactionID"),
    3: .same(proto: "includeDuplicates"),
    4: .standard(proto: "include_child_receipts"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._header) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._transactionID) }()
      case 3: try { try decoder.decodeSingularBoolField(value: &self.includeDuplicates) }()
      case 4: try { try decoder.decodeSingularBoolField(value: &self.includeChildReceipts) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._header {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try { if let v = self._transactionID {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    if self.includeDuplicates != false {
      try visitor.visitSingularBoolField(value: self.includeDuplicates, fieldNumber: 3)
    }
    if self.includeChildReceipts != false {
      try visitor.visitSingularBoolField(value: self.includeChildReceipts, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_TransactionGetReceiptQuery, rhs: Proto_TransactionGetReceiptQuery) -> Bool {
    if lhs._header != rhs._header {return false}
    if lhs._transactionID != rhs._transactionID {return false}
    if lhs.includeDuplicates != rhs.includeDuplicates {return false}
    if lhs.includeChildReceipts != rhs.includeChildReceipts {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Proto_TransactionGetReceiptResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".TransactionGetReceiptResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "header"),
    2: .same(proto: "receipt"),
    4: .same(proto: "duplicateTransactionReceipts"),
    5: .standard(proto: "child_transaction_receipts"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._header) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._receipt) }()
      case 4: try { try decoder.decodeRepeatedMessageField(value: &self.duplicateTransactionReceipts) }()
      case 5: try { try decoder.decodeRepeatedMessageField(value: &self.childTransactionReceipts) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._header {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try { if let v = self._receipt {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    if !self.duplicateTransactionReceipts.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.duplicateTransactionReceipts, fieldNumber: 4)
    }
    if !self.childTransactionReceipts.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.childTransactionReceipts, fieldNumber: 5)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_TransactionGetReceiptResponse, rhs: Proto_TransactionGetReceiptResponse) -> Bool {
    if lhs._header != rhs._header {return false}
    if lhs._receipt != rhs._receipt {return false}
    if lhs.duplicateTransactionReceipts != rhs.duplicateTransactionReceipts {return false}
    if lhs.childTransactionReceipts != rhs.childTransactionReceipts {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
