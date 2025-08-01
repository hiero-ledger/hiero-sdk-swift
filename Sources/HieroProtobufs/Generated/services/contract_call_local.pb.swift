// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: services/contract_call_local.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

///*
/// # Local Contract Call
/// A Contract Call executed directly on the current node
/// (that is, without consensus).
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
/// Call a view function of a given smart contract<br/>
/// The call must provide function parameter inputs as needed.<br/>
/// This is potentially useful for calling view functions that will not revert
/// when executed in a static EVM context. Many such use cases will be better
/// served by using a Mirror Node API, however.
///
/// This is performed locally on the particular node that the client is
/// communicating with. Executing the call locally is faster and less costly,
/// but imposes certain restrictions.<br/>
/// The call MUST NOT change the state of the contract instance. This also
/// precludes any expenditure or transfer of HBAR or other tokens.<br/>
/// The call SHALL NOT have a separate consensus timestamp.<br/>
/// The call SHALL NOT generate a record nor a receipt.<br/>
/// The response SHALL contain the output returned by the function call.<br/>
/// Any contract call that would use the `STATICCALL` opcode MAY be called via
/// contract call local with performance and cost benefits.
///
/// Unlike a ContractCall transaction, the node SHALL always consume the
/// _entire_ amount of offered "gas" in determining the fee for this query, so
/// accurate gas estimation is important.
public struct Proto_ContractCallLocalQuery: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///*
  /// Standard information sent with every query operation.<br/>
  /// This includes the signed payment and what kind of response is requested
  /// (cost, state proof, both, or neither).
  /// <p>
  /// The payment MUST be sufficient for the base fees _and_ the full amount
  /// in the `gas` field.
  public var header: Proto_QueryHeader {
    get {return _header ?? Proto_QueryHeader()}
    set {_header = newValue}
  }
  /// Returns true if `header` has been explicitly set.
  public var hasHeader: Bool {return self._header != nil}
  /// Clears the value of `header`. Subsequent reads from it will return its default value.
  public mutating func clearHeader() {self._header = nil}

  ///*
  /// The ID of a smart contract to call.
  public var contractID: Proto_ContractID {
    get {return _contractID ?? Proto_ContractID()}
    set {_contractID = newValue}
  }
  /// Returns true if `contractID` has been explicitly set.
  public var hasContractID: Bool {return self._contractID != nil}
  /// Clears the value of `contractID`. Subsequent reads from it will return its default value.
  public mutating func clearContractID() {self._contractID = nil}

  ///*
  /// The amount of "gas" to use for this call.
  /// <p>
  /// This transaction SHALL consume all of the gas offered and charge the
  /// corresponding fee according to the current exchange rate between
  /// HBAR and "gas".
  public var gas: Int64 = 0

  ///*
  /// The smart contract function to call, and the parameters to pass to that
  /// function.
  /// <p>
  /// These SHALL be presented in EVM bytecode function call format.
  public var functionParameters: Data = Data()

  ///*
  /// Do not use this field; it is ignored in the current software.
  /// <p>
  /// The maximum number of bytes that the result might include.<br/>
  /// The call will fail if it would have returned more than this number
  /// of bytes.
  ///
  /// NOTE: This field was marked as deprecated in the .proto file.
  public var maxResultSize: Int64 = 0

  ///*
  /// The account that is the "sender" for this contract call.
  /// <p>
  /// If this is not set it SHALL be interpreted as the accountId from the
  /// associated transactionId.<br/>
  /// If this is set then either the associated transaction or the foreign
  /// transaction data MUST be signed by the referenced account.
  public var senderID: Proto_AccountID {
    get {return _senderID ?? Proto_AccountID()}
    set {_senderID = newValue}
  }
  /// Returns true if `senderID` has been explicitly set.
  public var hasSenderID: Bool {return self._senderID != nil}
  /// Clears the value of `senderID`. Subsequent reads from it will return its default value.
  public mutating func clearSenderID() {self._senderID = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _header: Proto_QueryHeader? = nil
  fileprivate var _contractID: Proto_ContractID? = nil
  fileprivate var _senderID: Proto_AccountID? = nil
}

///*
/// The response returned by a `ContractCallLocalQuery` transaction.
public struct Proto_ContractCallLocalResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///*
  /// The standard response information for queries.<br/>
  /// This includes the values requested in the `QueryHeader`
  /// (cost, state proof, both, or neither).
  public var header: Proto_ResponseHeader {
    get {return _header ?? Proto_ResponseHeader()}
    set {_header = newValue}
  }
  /// Returns true if `header` has been explicitly set.
  public var hasHeader: Bool {return self._header != nil}
  /// Clears the value of `header`. Subsequent reads from it will return its default value.
  public mutating func clearHeader() {self._header = nil}

  ///*
  /// The result(s) returned by the function call, if successful.
  /// <p>
  /// If the call failed this value SHALL be unset.
  public var functionResult: Proto_ContractFunctionResult {
    get {return _functionResult ?? Proto_ContractFunctionResult()}
    set {_functionResult = newValue}
  }
  /// Returns true if `functionResult` has been explicitly set.
  public var hasFunctionResult: Bool {return self._functionResult != nil}
  /// Clears the value of `functionResult`. Subsequent reads from it will return its default value.
  public mutating func clearFunctionResult() {self._functionResult = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _header: Proto_ResponseHeader? = nil
  fileprivate var _functionResult: Proto_ContractFunctionResult? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "proto"

extension Proto_ContractCallLocalQuery: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ContractCallLocalQuery"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "header"),
    2: .same(proto: "contractID"),
    3: .same(proto: "gas"),
    4: .same(proto: "functionParameters"),
    5: .same(proto: "maxResultSize"),
    6: .standard(proto: "sender_id"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._header) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._contractID) }()
      case 3: try { try decoder.decodeSingularInt64Field(value: &self.gas) }()
      case 4: try { try decoder.decodeSingularBytesField(value: &self.functionParameters) }()
      case 5: try { try decoder.decodeSingularInt64Field(value: &self.maxResultSize) }()
      case 6: try { try decoder.decodeSingularMessageField(value: &self._senderID) }()
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
    try { if let v = self._contractID {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    if self.gas != 0 {
      try visitor.visitSingularInt64Field(value: self.gas, fieldNumber: 3)
    }
    if !self.functionParameters.isEmpty {
      try visitor.visitSingularBytesField(value: self.functionParameters, fieldNumber: 4)
    }
    if self.maxResultSize != 0 {
      try visitor.visitSingularInt64Field(value: self.maxResultSize, fieldNumber: 5)
    }
    try { if let v = self._senderID {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 6)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_ContractCallLocalQuery, rhs: Proto_ContractCallLocalQuery) -> Bool {
    if lhs._header != rhs._header {return false}
    if lhs._contractID != rhs._contractID {return false}
    if lhs.gas != rhs.gas {return false}
    if lhs.functionParameters != rhs.functionParameters {return false}
    if lhs.maxResultSize != rhs.maxResultSize {return false}
    if lhs._senderID != rhs._senderID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Proto_ContractCallLocalResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ContractCallLocalResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "header"),
    2: .same(proto: "functionResult"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._header) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._functionResult) }()
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
    try { if let v = self._functionResult {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_ContractCallLocalResponse, rhs: Proto_ContractCallLocalResponse) -> Bool {
    if lhs._header != rhs._header {return false}
    if lhs._functionResult != rhs._functionResult {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
