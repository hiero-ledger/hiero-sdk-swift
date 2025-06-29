// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: services/contract_get_info.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

///*
/// # Contract Get Info
/// A standard query to obtain detailed information about a smart contract.
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
/// Request detailed information about a smart contract.
public struct Proto_ContractGetInfoQuery: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///*
  /// Standard information sent with every query operation.<br/>
  /// This includes the signed payment and what kind of response is requested
  /// (cost, state proof, both, or neither).
  public var header: Proto_QueryHeader {
    get {return _header ?? Proto_QueryHeader()}
    set {_header = newValue}
  }
  /// Returns true if `header` has been explicitly set.
  public var hasHeader: Bool {return self._header != nil}
  /// Clears the value of `header`. Subsequent reads from it will return its default value.
  public mutating func clearHeader() {self._header = nil}

  ///*
  /// A smart contract ID.
  /// <p>
  /// The network SHALL return information for this smart contract,
  /// if successful.
  public var contractID: Proto_ContractID {
    get {return _contractID ?? Proto_ContractID()}
    set {_contractID = newValue}
  }
  /// Returns true if `contractID` has been explicitly set.
  public var hasContractID: Bool {return self._contractID != nil}
  /// Clears the value of `contractID`. Subsequent reads from it will return its default value.
  public mutating func clearContractID() {self._contractID = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _header: Proto_QueryHeader? = nil
  fileprivate var _contractID: Proto_ContractID? = nil
}

///*
/// Information returned in response to a "get info" query for a smart contract.
public struct Proto_ContractGetInfoResponse: Sendable {
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
  /// The information, as requested, for a smart contract.
  /// A state proof MAY be generated for this value.
  public var contractInfo: Proto_ContractGetInfoResponse.ContractInfo {
    get {return _contractInfo ?? Proto_ContractGetInfoResponse.ContractInfo()}
    set {_contractInfo = newValue}
  }
  /// Returns true if `contractInfo` has been explicitly set.
  public var hasContractInfo: Bool {return self._contractInfo != nil}
  /// Clears the value of `contractInfo`. Subsequent reads from it will return its default value.
  public mutating func clearContractInfo() {self._contractInfo = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public struct ContractInfo: @unchecked Sendable {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    ///*
    /// The ID of the smart contract requested in the query.
    public var contractID: Proto_ContractID {
      get {return _storage._contractID ?? Proto_ContractID()}
      set {_uniqueStorage()._contractID = newValue}
    }
    /// Returns true if `contractID` has been explicitly set.
    public var hasContractID: Bool {return _storage._contractID != nil}
    /// Clears the value of `contractID`. Subsequent reads from it will return its default value.
    public mutating func clearContractID() {_uniqueStorage()._contractID = nil}

    ///*
    /// The Account ID for the account entry associated with this
    /// smart contract.
    public var accountID: Proto_AccountID {
      get {return _storage._accountID ?? Proto_AccountID()}
      set {_uniqueStorage()._accountID = newValue}
    }
    /// Returns true if `accountID` has been explicitly set.
    public var hasAccountID: Bool {return _storage._accountID != nil}
    /// Clears the value of `accountID`. Subsequent reads from it will return its default value.
    public mutating func clearAccountID() {_uniqueStorage()._accountID = nil}

    ///*
    /// The "Solidity" form contract ID.<br/>
    /// This is a hexadecimal string form of the 20-byte EVM address
    /// of the contract.
    public var contractAccountID: String {
      get {return _storage._contractAccountID}
      set {_uniqueStorage()._contractAccountID = newValue}
    }

    ///*
    /// The key that MUST sign any transaction to update or modify this
    /// smart contract.
    /// <p>
    /// If this value is null, or is an empty `KeyList` then the contract
    /// CANNOT be deleted, modified, or updated, but MAY still expire.
    public var adminKey: Proto_Key {
      get {return _storage._adminKey ?? Proto_Key()}
      set {_uniqueStorage()._adminKey = newValue}
    }
    /// Returns true if `adminKey` has been explicitly set.
    public var hasAdminKey: Bool {return _storage._adminKey != nil}
    /// Clears the value of `adminKey`. Subsequent reads from it will return its default value.
    public mutating func clearAdminKey() {_uniqueStorage()._adminKey = nil}

    ///*
    /// The point in time at which this contract will expire.
    public var expirationTime: Proto_Timestamp {
      get {return _storage._expirationTime ?? Proto_Timestamp()}
      set {_uniqueStorage()._expirationTime = newValue}
    }
    /// Returns true if `expirationTime` has been explicitly set.
    public var hasExpirationTime: Bool {return _storage._expirationTime != nil}
    /// Clears the value of `expirationTime`. Subsequent reads from it will return its default value.
    public mutating func clearExpirationTime() {_uniqueStorage()._expirationTime = nil}

    ///*
    /// The duration, in seconds, for which the contract lifetime will be
    /// automatically extended upon expiration, provide sufficient HBAR is
    /// available at that time to pay the renewal fee.<br/>
    /// See `auto_renew_account_id` for additional conditions.
    public var autoRenewPeriod: Proto_Duration {
      get {return _storage._autoRenewPeriod ?? Proto_Duration()}
      set {_uniqueStorage()._autoRenewPeriod = newValue}
    }
    /// Returns true if `autoRenewPeriod` has been explicitly set.
    public var hasAutoRenewPeriod: Bool {return _storage._autoRenewPeriod != nil}
    /// Clears the value of `autoRenewPeriod`. Subsequent reads from it will return its default value.
    public mutating func clearAutoRenewPeriod() {_uniqueStorage()._autoRenewPeriod = nil}

    ///*
    /// The amount of storage used by this smart contract.
    public var storage: Int64 {
      get {return _storage._storage}
      set {_uniqueStorage()._storage = newValue}
    }

    ///*
    /// A short description of this smart contract.
    /// <p>
    /// This value, if set, MUST NOT exceed `transaction.maxMemoUtf8Bytes`
    /// (default 100) bytes when encoded as UTF-8.
    public var memo: String {
      get {return _storage._memo}
      set {_uniqueStorage()._memo = newValue}
    }

    ///*
    /// The current HBAR balance, in tinybar, of the smart contract account.
    public var balance: UInt64 {
      get {return _storage._balance}
      set {_uniqueStorage()._balance = newValue}
    }

    ///*
    /// A flag indicating that this contract is deleted.
    public var deleted: Bool {
      get {return _storage._deleted}
      set {_uniqueStorage()._deleted = newValue}
    }

    ///*
    /// Because <a href="https://hips.hedera.com/hip/hip-367">HIP-367</a>,
    /// which allows an account to be associated to an unlimited number of
    /// tokens, it became necessary to only provide this information from
    /// a Mirror Node.<br/>
    /// The list of tokens associated to this contract.
    ///
    /// NOTE: This field was marked as deprecated in the .proto file.
    public var tokenRelationships: [Proto_TokenRelationship] {
      get {return _storage._tokenRelationships}
      set {_uniqueStorage()._tokenRelationships = newValue}
    }

    ///*
    /// The ledger ID of the network that generated this response.
    /// <p>
    /// This value SHALL identify the distributed ledger that responded to
    /// this query.
    public var ledgerID: Data {
      get {return _storage._ledgerID}
      set {_uniqueStorage()._ledgerID = newValue}
    }

    ///*
    /// An account designated to pay the renewal fee upon automatic renewal
    /// of this contract.
    /// <p>
    /// If this is not set, or is set to an account with zero HBAR
    /// available, the HBAR balance of the contract, if available,
    /// SHALL be used to pay the renewal fee.
    public var autoRenewAccountID: Proto_AccountID {
      get {return _storage._autoRenewAccountID ?? Proto_AccountID()}
      set {_uniqueStorage()._autoRenewAccountID = newValue}
    }
    /// Returns true if `autoRenewAccountID` has been explicitly set.
    public var hasAutoRenewAccountID: Bool {return _storage._autoRenewAccountID != nil}
    /// Clears the value of `autoRenewAccountID`. Subsequent reads from it will return its default value.
    public mutating func clearAutoRenewAccountID() {_uniqueStorage()._autoRenewAccountID = nil}

    ///*
    /// The maximum number of tokens that the contract can be
    /// associated to automatically.
    public var maxAutomaticTokenAssociations: Int32 {
      get {return _storage._maxAutomaticTokenAssociations}
      set {_uniqueStorage()._maxAutomaticTokenAssociations = newValue}
    }

    ///*
    /// Staking information for this contract.
    public var stakingInfo: Proto_StakingInfo {
      get {return _storage._stakingInfo ?? Proto_StakingInfo()}
      set {_uniqueStorage()._stakingInfo = newValue}
    }
    /// Returns true if `stakingInfo` has been explicitly set.
    public var hasStakingInfo: Bool {return _storage._stakingInfo != nil}
    /// Clears the value of `stakingInfo`. Subsequent reads from it will return its default value.
    public mutating func clearStakingInfo() {_uniqueStorage()._stakingInfo = nil}

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}

    fileprivate var _storage = _StorageClass.defaultInstance
  }

  public init() {}

  fileprivate var _header: Proto_ResponseHeader? = nil
  fileprivate var _contractInfo: Proto_ContractGetInfoResponse.ContractInfo? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "proto"

extension Proto_ContractGetInfoQuery: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ContractGetInfoQuery"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "header"),
    2: .same(proto: "contractID"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._header) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._contractID) }()
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
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_ContractGetInfoQuery, rhs: Proto_ContractGetInfoQuery) -> Bool {
    if lhs._header != rhs._header {return false}
    if lhs._contractID != rhs._contractID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Proto_ContractGetInfoResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ContractGetInfoResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "header"),
    2: .same(proto: "contractInfo"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._header) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._contractInfo) }()
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
    try { if let v = self._contractInfo {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_ContractGetInfoResponse, rhs: Proto_ContractGetInfoResponse) -> Bool {
    if lhs._header != rhs._header {return false}
    if lhs._contractInfo != rhs._contractInfo {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Proto_ContractGetInfoResponse.ContractInfo: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Proto_ContractGetInfoResponse.protoMessageName + ".ContractInfo"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "contractID"),
    2: .same(proto: "accountID"),
    3: .same(proto: "contractAccountID"),
    4: .same(proto: "adminKey"),
    5: .same(proto: "expirationTime"),
    6: .same(proto: "autoRenewPeriod"),
    7: .same(proto: "storage"),
    8: .same(proto: "memo"),
    9: .same(proto: "balance"),
    10: .same(proto: "deleted"),
    11: .same(proto: "tokenRelationships"),
    12: .standard(proto: "ledger_id"),
    13: .standard(proto: "auto_renew_account_id"),
    14: .standard(proto: "max_automatic_token_associations"),
    15: .standard(proto: "staking_info"),
  ]

  fileprivate class _StorageClass {
    var _contractID: Proto_ContractID? = nil
    var _accountID: Proto_AccountID? = nil
    var _contractAccountID: String = String()
    var _adminKey: Proto_Key? = nil
    var _expirationTime: Proto_Timestamp? = nil
    var _autoRenewPeriod: Proto_Duration? = nil
    var _storage: Int64 = 0
    var _memo: String = String()
    var _balance: UInt64 = 0
    var _deleted: Bool = false
    var _tokenRelationships: [Proto_TokenRelationship] = []
    var _ledgerID: Data = Data()
    var _autoRenewAccountID: Proto_AccountID? = nil
    var _maxAutomaticTokenAssociations: Int32 = 0
    var _stakingInfo: Proto_StakingInfo? = nil

    #if swift(>=5.10)
      // This property is used as the initial default value for new instances of the type.
      // The type itself is protecting the reference to its storage via CoW semantics.
      // This will force a copy to be made of this reference when the first mutation occurs;
      // hence, it is safe to mark this as `nonisolated(unsafe)`.
      static nonisolated(unsafe) let defaultInstance = _StorageClass()
    #else
      static let defaultInstance = _StorageClass()
    #endif

    private init() {}

    init(copying source: _StorageClass) {
      _contractID = source._contractID
      _accountID = source._accountID
      _contractAccountID = source._contractAccountID
      _adminKey = source._adminKey
      _expirationTime = source._expirationTime
      _autoRenewPeriod = source._autoRenewPeriod
      _storage = source._storage
      _memo = source._memo
      _balance = source._balance
      _deleted = source._deleted
      _tokenRelationships = source._tokenRelationships
      _ledgerID = source._ledgerID
      _autoRenewAccountID = source._autoRenewAccountID
      _maxAutomaticTokenAssociations = source._maxAutomaticTokenAssociations
      _stakingInfo = source._stakingInfo
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        // The use of inline closures is to circumvent an issue where the compiler
        // allocates stack space for every case branch when no optimizations are
        // enabled. https://github.com/apple/swift-protobuf/issues/1034
        switch fieldNumber {
        case 1: try { try decoder.decodeSingularMessageField(value: &_storage._contractID) }()
        case 2: try { try decoder.decodeSingularMessageField(value: &_storage._accountID) }()
        case 3: try { try decoder.decodeSingularStringField(value: &_storage._contractAccountID) }()
        case 4: try { try decoder.decodeSingularMessageField(value: &_storage._adminKey) }()
        case 5: try { try decoder.decodeSingularMessageField(value: &_storage._expirationTime) }()
        case 6: try { try decoder.decodeSingularMessageField(value: &_storage._autoRenewPeriod) }()
        case 7: try { try decoder.decodeSingularInt64Field(value: &_storage._storage) }()
        case 8: try { try decoder.decodeSingularStringField(value: &_storage._memo) }()
        case 9: try { try decoder.decodeSingularUInt64Field(value: &_storage._balance) }()
        case 10: try { try decoder.decodeSingularBoolField(value: &_storage._deleted) }()
        case 11: try { try decoder.decodeRepeatedMessageField(value: &_storage._tokenRelationships) }()
        case 12: try { try decoder.decodeSingularBytesField(value: &_storage._ledgerID) }()
        case 13: try { try decoder.decodeSingularMessageField(value: &_storage._autoRenewAccountID) }()
        case 14: try { try decoder.decodeSingularInt32Field(value: &_storage._maxAutomaticTokenAssociations) }()
        case 15: try { try decoder.decodeSingularMessageField(value: &_storage._stakingInfo) }()
        default: break
        }
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every if/case branch local when no optimizations
      // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
      // https://github.com/apple/swift-protobuf/issues/1182
      try { if let v = _storage._contractID {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
      } }()
      try { if let v = _storage._accountID {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
      } }()
      if !_storage._contractAccountID.isEmpty {
        try visitor.visitSingularStringField(value: _storage._contractAccountID, fieldNumber: 3)
      }
      try { if let v = _storage._adminKey {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
      } }()
      try { if let v = _storage._expirationTime {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
      } }()
      try { if let v = _storage._autoRenewPeriod {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 6)
      } }()
      if _storage._storage != 0 {
        try visitor.visitSingularInt64Field(value: _storage._storage, fieldNumber: 7)
      }
      if !_storage._memo.isEmpty {
        try visitor.visitSingularStringField(value: _storage._memo, fieldNumber: 8)
      }
      if _storage._balance != 0 {
        try visitor.visitSingularUInt64Field(value: _storage._balance, fieldNumber: 9)
      }
      if _storage._deleted != false {
        try visitor.visitSingularBoolField(value: _storage._deleted, fieldNumber: 10)
      }
      if !_storage._tokenRelationships.isEmpty {
        try visitor.visitRepeatedMessageField(value: _storage._tokenRelationships, fieldNumber: 11)
      }
      if !_storage._ledgerID.isEmpty {
        try visitor.visitSingularBytesField(value: _storage._ledgerID, fieldNumber: 12)
      }
      try { if let v = _storage._autoRenewAccountID {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 13)
      } }()
      if _storage._maxAutomaticTokenAssociations != 0 {
        try visitor.visitSingularInt32Field(value: _storage._maxAutomaticTokenAssociations, fieldNumber: 14)
      }
      try { if let v = _storage._stakingInfo {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 15)
      } }()
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_ContractGetInfoResponse.ContractInfo, rhs: Proto_ContractGetInfoResponse.ContractInfo) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._contractID != rhs_storage._contractID {return false}
        if _storage._accountID != rhs_storage._accountID {return false}
        if _storage._contractAccountID != rhs_storage._contractAccountID {return false}
        if _storage._adminKey != rhs_storage._adminKey {return false}
        if _storage._expirationTime != rhs_storage._expirationTime {return false}
        if _storage._autoRenewPeriod != rhs_storage._autoRenewPeriod {return false}
        if _storage._storage != rhs_storage._storage {return false}
        if _storage._memo != rhs_storage._memo {return false}
        if _storage._balance != rhs_storage._balance {return false}
        if _storage._deleted != rhs_storage._deleted {return false}
        if _storage._tokenRelationships != rhs_storage._tokenRelationships {return false}
        if _storage._ledgerID != rhs_storage._ledgerID {return false}
        if _storage._autoRenewAccountID != rhs_storage._autoRenewAccountID {return false}
        if _storage._maxAutomaticTokenAssociations != rhs_storage._maxAutomaticTokenAssociations {return false}
        if _storage._stakingInfo != rhs_storage._stakingInfo {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
