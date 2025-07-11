// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: services/crypto_get_info.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

///*
/// # Get Account Information
/// A standard query to inspect the full detail of an account.
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
/// A query to read information for an account.
///
/// The returned information SHALL include balance.<br/>
/// The returned information SHALL NOT include allowances.<br/>
/// The returned information SHALL NOT include token relationships.<br/>
/// The returned information SHALL NOT include account records.
public struct Proto_CryptoGetInfoQuery: Sendable {
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
  /// The account ID for which information is requested
  public var accountID: Proto_AccountID {
    get {return _accountID ?? Proto_AccountID()}
    set {_accountID = newValue}
  }
  /// Returns true if `accountID` has been explicitly set.
  public var hasAccountID: Bool {return self._accountID != nil}
  /// Clears the value of `accountID`. Subsequent reads from it will return its default value.
  public mutating func clearAccountID() {self._accountID = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _header: Proto_QueryHeader? = nil
  fileprivate var _accountID: Proto_AccountID? = nil
}

///*
/// Response when the client sends the node CryptoGetInfoQuery
public struct Proto_CryptoGetInfoResponse: Sendable {
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
  /// Details of the account.
  /// <p>
  /// A state proof MAY be generated for this field.
  public var accountInfo: Proto_CryptoGetInfoResponse.AccountInfo {
    get {return _accountInfo ?? Proto_CryptoGetInfoResponse.AccountInfo()}
    set {_accountInfo = newValue}
  }
  /// Returns true if `accountInfo` has been explicitly set.
  public var hasAccountInfo: Bool {return self._accountInfo != nil}
  /// Clears the value of `accountInfo`. Subsequent reads from it will return its default value.
  public mutating func clearAccountInfo() {self._accountInfo = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  ///*
  /// Information describing A single Account in the Hedera distributed ledger.
  ///
  /// #### Attributes
  /// Each Account may have a unique three-part identifier, a Key, and one or
  /// more token balances. Accounts also have an alias, which has multiple
  /// forms, and may be set automatically. Several additional items are
  /// associated with the Account to enable full functionality.
  ///
  /// #### Expiration
  /// Accounts, as most items in the network, have an expiration time, recorded
  /// as a `Timestamp`, and must be "renewed" for a small fee at expiration.
  /// This helps to reduce the amount of inactive accounts retained in state.
  /// Another account may be designated to pay any renewal fees and
  /// automatically renew the account for (by default) 30-90 days at a time as
  /// a means to optionally ensure important accounts remain active.
  ///
  /// ### Staking
  /// Accounts may participate in securing the network by "staking" the account
  /// balances to a particular network node, and receive a portion of network
  /// fees as a reward. An account may optionally decline these rewards but
  /// still stake its balances.
  ///
  /// #### Transfer Restrictions
  /// An account may optionally require that inbound transfer transactions be
  /// signed by that account as receiver (in addition to any other signatures
  /// required, including sender).
  public struct AccountInfo: @unchecked Sendable {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    ///*
    /// a unique identifier for this account.
    /// <p>
    /// An account identifier, when assigned to this field, SHALL be of
    /// the form `shard.realm.number`.
    public var accountID: Proto_AccountID {
      get {return _storage._accountID ?? Proto_AccountID()}
      set {_uniqueStorage()._accountID = newValue}
    }
    /// Returns true if `accountID` has been explicitly set.
    public var hasAccountID: Bool {return _storage._accountID != nil}
    /// Clears the value of `accountID`. Subsequent reads from it will return its default value.
    public mutating func clearAccountID() {_uniqueStorage()._accountID = nil}

    ///*
    /// A Solidity ID.
    /// <p>
    /// This SHALL be populated if this account is a smart contract, and
    /// SHALL NOT be populated otherwise.<br/>
    /// This SHALL be formatted as a string according to Solidity ID
    /// standards.
    public var contractAccountID: String {
      get {return _storage._contractAccountID}
      set {_uniqueStorage()._contractAccountID = newValue}
    }

    ///*
    /// A boolean indicating that this account is deleted.
    /// <p>
    /// Any transaction involving a deleted account SHALL fail.
    public var deleted: Bool {
      get {return _storage._deleted}
      set {_uniqueStorage()._deleted = newValue}
    }

    ///*
    /// Replaced by StakingInfo.<br/>
    /// ID of the account to which this account is staking its balances. If
    /// this account is not currently staking its balances, then this field,
    /// if set, SHALL be the sentinel value of `0.0.0`.
    ///
    /// NOTE: This field was marked as deprecated in the .proto file.
    public var proxyAccountID: Proto_AccountID {
      get {return _storage._proxyAccountID ?? Proto_AccountID()}
      set {_uniqueStorage()._proxyAccountID = newValue}
    }
    /// Returns true if `proxyAccountID` has been explicitly set.
    public var hasProxyAccountID: Bool {return _storage._proxyAccountID != nil}
    /// Clears the value of `proxyAccountID`. Subsequent reads from it will return its default value.
    public mutating func clearProxyAccountID() {_uniqueStorage()._proxyAccountID = nil}

    ///*
    /// Replaced by StakingInfo.<br/>
    /// The total amount of tinybar proxy staked to this account.
    ///
    /// NOTE: This field was marked as deprecated in the .proto file.
    public var proxyReceived: Int64 {
      get {return _storage._proxyReceived}
      set {_uniqueStorage()._proxyReceived = newValue}
    }

    ///*
    /// The key to be used to sign transactions from this account, if any.
    /// <p>
    /// This key SHALL NOT be set for hollow accounts until the account
    /// is finalized.<br/>
    /// This key SHALL be set on all other accounts, except for certain
    /// immutable accounts (0.0.800 and 0.0.801) necessary for network
    /// function and otherwise secured by the governing council.
    public var key: Proto_Key {
      get {return _storage._key ?? Proto_Key()}
      set {_uniqueStorage()._key = newValue}
    }
    /// Returns true if `key` has been explicitly set.
    public var hasKey: Bool {return _storage._key != nil}
    /// Clears the value of `key`. Subsequent reads from it will return its default value.
    public mutating func clearKey() {_uniqueStorage()._key = nil}

    ///*
    /// The HBAR balance of this account, in tinybar (10<sup>-8</sup> HBAR).
    /// <p>
    /// This value SHALL always be a whole number.
    public var balance: UInt64 {
      get {return _storage._balance}
      set {_uniqueStorage()._balance = newValue}
    }

    ///*
    /// Obsolete and unused.<br/>
    /// The threshold amount, in tinybars, at which a record was created for
    /// any transaction that decreased the balance of this account.
    ///
    /// NOTE: This field was marked as deprecated in the .proto file.
    public var generateSendRecordThreshold: UInt64 {
      get {return _storage._generateSendRecordThreshold}
      set {_uniqueStorage()._generateSendRecordThreshold = newValue}
    }

    ///*
    /// Obsolete and unused.<br/>
    /// The threshold amount, in tinybars, at which a record was created for
    /// any transaction that increased the balance of this account.
    ///
    /// NOTE: This field was marked as deprecated in the .proto file.
    public var generateReceiveRecordThreshold: UInt64 {
      get {return _storage._generateReceiveRecordThreshold}
      set {_uniqueStorage()._generateReceiveRecordThreshold = newValue}
    }

    ///*
    /// A boolean indicating that the account requires a receiver signature
    /// for inbound token transfer transactions.
    /// <p>
    /// If this value is `true` then a transaction to transfer tokens to this
    /// account SHALL NOT succeed unless this account has signed the
    /// transfer transaction.
    public var receiverSigRequired: Bool {
      get {return _storage._receiverSigRequired}
      set {_uniqueStorage()._receiverSigRequired = newValue}
    }

    ///*
    /// The current expiration time for this account.
    /// <p>
    /// This account SHALL be due standard renewal fees when the network
    /// consensus time exceeds this time.<br/>
    /// If rent and expiration are enabled for the network, and automatic
    /// renewal is enabled for this account, renewal fees SHALL be charged
    /// after this time, and, if charged, the expiration time SHALL be
    /// extended for another renewal period.<br/>
    /// This account MAY be expired and removed from state at any point
    /// after this time if not renewed.<br/>
    /// An account holder MAY extend this time by submitting an account
    /// update transaction to modify expiration time, subject to the current
    /// maximum expiration time for the network.
    public var expirationTime: Proto_Timestamp {
      get {return _storage._expirationTime ?? Proto_Timestamp()}
      set {_uniqueStorage()._expirationTime = newValue}
    }
    /// Returns true if `expirationTime` has been explicitly set.
    public var hasExpirationTime: Bool {return _storage._expirationTime != nil}
    /// Clears the value of `expirationTime`. Subsequent reads from it will return its default value.
    public mutating func clearExpirationTime() {_uniqueStorage()._expirationTime = nil}

    ///*
    /// A duration to extend this account's expiration.
    /// <p>
    /// The network SHALL extend the account's expiration by this
    /// duration, if funds are available, upon automatic renewal.<br/>
    /// This SHALL NOT apply if the account is already deleted
    /// upon expiration.<br/>
    /// If this is not provided in an allowed range on account creation, the
    /// transaction SHALL fail with INVALID_AUTO_RENEWAL_PERIOD. The default
    /// values for the minimum period and maximum period are currently
    /// 30 days and 90 days, respectively.
    public var autoRenewPeriod: Proto_Duration {
      get {return _storage._autoRenewPeriod ?? Proto_Duration()}
      set {_uniqueStorage()._autoRenewPeriod = newValue}
    }
    /// Returns true if `autoRenewPeriod` has been explicitly set.
    public var hasAutoRenewPeriod: Bool {return _storage._autoRenewPeriod != nil}
    /// Clears the value of `autoRenewPeriod`. Subsequent reads from it will return its default value.
    public mutating func clearAutoRenewPeriod() {_uniqueStorage()._autoRenewPeriod = nil}

    ///*
    /// All of the livehashes attached to the account (each of which is a
    /// hash along with the keys that authorized it and can delete it)
    public var liveHashes: [Proto_LiveHash] {
      get {return _storage._liveHashes}
      set {_uniqueStorage()._liveHashes = newValue}
    }

    ///*
    /// As of `HIP-367`, which enabled unlimited token associations, the
    /// potential scale for this value requires that users consult a mirror
    /// node for this information.
    ///
    /// NOTE: This field was marked as deprecated in the .proto file.
    public var tokenRelationships: [Proto_TokenRelationship] {
      get {return _storage._tokenRelationships}
      set {_uniqueStorage()._tokenRelationships = newValue}
    }

    ///*
    /// A short description of this account.
    /// <p>
    /// This value, if set, MUST NOT exceed `transaction.maxMemoUtf8Bytes`
    /// (default 100) bytes when encoded as UTF-8.
    public var memo: String {
      get {return _storage._memo}
      set {_uniqueStorage()._memo = newValue}
    }

    ///*
    /// The total number of non-fungible/unique tokens owned by this account.
    public var ownedNfts: Int64 {
      get {return _storage._ownedNfts}
      set {_uniqueStorage()._ownedNfts = newValue}
    }

    ///*
    /// The maximum number of tokens that can be auto-associated with the
    /// account.
    /// <p>
    /// If this is less than or equal to `used_auto_associations` (or 0),
    /// then this account MUST manually associate with a token before
    /// transacting in that token.<br/>
    /// Following HIP-904 This value may also be `-1` to indicate no
    /// limit.<br/>
    /// This value MUST NOT be less than `-1`.
    public var maxAutomaticTokenAssociations: Int32 {
      get {return _storage._maxAutomaticTokenAssociations}
      set {_uniqueStorage()._maxAutomaticTokenAssociations = newValue}
    }

    ///*
    /// An account alias.<br/>
    /// This is a value used in some contexts to reference an account when
    /// the tripartite account identifier is not available.
    /// <p>
    /// This field, when set to a non-default value, is immutable and
    /// SHALL NOT be changed.
    public var alias: Data {
      get {return _storage._alias}
      set {_uniqueStorage()._alias = newValue}
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
    /// The ethereum transaction nonce associated with this account.
    public var ethereumNonce: Int64 {
      get {return _storage._ethereumNonce}
      set {_uniqueStorage()._ethereumNonce = newValue}
    }

    ///*
    /// Staking information for this account.
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
  fileprivate var _accountInfo: Proto_CryptoGetInfoResponse.AccountInfo? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "proto"

extension Proto_CryptoGetInfoQuery: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".CryptoGetInfoQuery"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "header"),
    2: .same(proto: "accountID"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._header) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._accountID) }()
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
    try { if let v = self._accountID {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_CryptoGetInfoQuery, rhs: Proto_CryptoGetInfoQuery) -> Bool {
    if lhs._header != rhs._header {return false}
    if lhs._accountID != rhs._accountID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Proto_CryptoGetInfoResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".CryptoGetInfoResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "header"),
    2: .same(proto: "accountInfo"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._header) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._accountInfo) }()
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
    try { if let v = self._accountInfo {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_CryptoGetInfoResponse, rhs: Proto_CryptoGetInfoResponse) -> Bool {
    if lhs._header != rhs._header {return false}
    if lhs._accountInfo != rhs._accountInfo {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Proto_CryptoGetInfoResponse.AccountInfo: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Proto_CryptoGetInfoResponse.protoMessageName + ".AccountInfo"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "accountID"),
    2: .same(proto: "contractAccountID"),
    3: .same(proto: "deleted"),
    4: .same(proto: "proxyAccountID"),
    6: .same(proto: "proxyReceived"),
    7: .same(proto: "key"),
    8: .same(proto: "balance"),
    9: .same(proto: "generateSendRecordThreshold"),
    10: .same(proto: "generateReceiveRecordThreshold"),
    11: .same(proto: "receiverSigRequired"),
    12: .same(proto: "expirationTime"),
    13: .same(proto: "autoRenewPeriod"),
    14: .same(proto: "liveHashes"),
    15: .same(proto: "tokenRelationships"),
    16: .same(proto: "memo"),
    17: .same(proto: "ownedNfts"),
    18: .standard(proto: "max_automatic_token_associations"),
    19: .same(proto: "alias"),
    20: .standard(proto: "ledger_id"),
    21: .standard(proto: "ethereum_nonce"),
    22: .standard(proto: "staking_info"),
  ]

  fileprivate class _StorageClass {
    var _accountID: Proto_AccountID? = nil
    var _contractAccountID: String = String()
    var _deleted: Bool = false
    var _proxyAccountID: Proto_AccountID? = nil
    var _proxyReceived: Int64 = 0
    var _key: Proto_Key? = nil
    var _balance: UInt64 = 0
    var _generateSendRecordThreshold: UInt64 = 0
    var _generateReceiveRecordThreshold: UInt64 = 0
    var _receiverSigRequired: Bool = false
    var _expirationTime: Proto_Timestamp? = nil
    var _autoRenewPeriod: Proto_Duration? = nil
    var _liveHashes: [Proto_LiveHash] = []
    var _tokenRelationships: [Proto_TokenRelationship] = []
    var _memo: String = String()
    var _ownedNfts: Int64 = 0
    var _maxAutomaticTokenAssociations: Int32 = 0
    var _alias: Data = Data()
    var _ledgerID: Data = Data()
    var _ethereumNonce: Int64 = 0
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
      _accountID = source._accountID
      _contractAccountID = source._contractAccountID
      _deleted = source._deleted
      _proxyAccountID = source._proxyAccountID
      _proxyReceived = source._proxyReceived
      _key = source._key
      _balance = source._balance
      _generateSendRecordThreshold = source._generateSendRecordThreshold
      _generateReceiveRecordThreshold = source._generateReceiveRecordThreshold
      _receiverSigRequired = source._receiverSigRequired
      _expirationTime = source._expirationTime
      _autoRenewPeriod = source._autoRenewPeriod
      _liveHashes = source._liveHashes
      _tokenRelationships = source._tokenRelationships
      _memo = source._memo
      _ownedNfts = source._ownedNfts
      _maxAutomaticTokenAssociations = source._maxAutomaticTokenAssociations
      _alias = source._alias
      _ledgerID = source._ledgerID
      _ethereumNonce = source._ethereumNonce
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
        case 1: try { try decoder.decodeSingularMessageField(value: &_storage._accountID) }()
        case 2: try { try decoder.decodeSingularStringField(value: &_storage._contractAccountID) }()
        case 3: try { try decoder.decodeSingularBoolField(value: &_storage._deleted) }()
        case 4: try { try decoder.decodeSingularMessageField(value: &_storage._proxyAccountID) }()
        case 6: try { try decoder.decodeSingularInt64Field(value: &_storage._proxyReceived) }()
        case 7: try { try decoder.decodeSingularMessageField(value: &_storage._key) }()
        case 8: try { try decoder.decodeSingularUInt64Field(value: &_storage._balance) }()
        case 9: try { try decoder.decodeSingularUInt64Field(value: &_storage._generateSendRecordThreshold) }()
        case 10: try { try decoder.decodeSingularUInt64Field(value: &_storage._generateReceiveRecordThreshold) }()
        case 11: try { try decoder.decodeSingularBoolField(value: &_storage._receiverSigRequired) }()
        case 12: try { try decoder.decodeSingularMessageField(value: &_storage._expirationTime) }()
        case 13: try { try decoder.decodeSingularMessageField(value: &_storage._autoRenewPeriod) }()
        case 14: try { try decoder.decodeRepeatedMessageField(value: &_storage._liveHashes) }()
        case 15: try { try decoder.decodeRepeatedMessageField(value: &_storage._tokenRelationships) }()
        case 16: try { try decoder.decodeSingularStringField(value: &_storage._memo) }()
        case 17: try { try decoder.decodeSingularInt64Field(value: &_storage._ownedNfts) }()
        case 18: try { try decoder.decodeSingularInt32Field(value: &_storage._maxAutomaticTokenAssociations) }()
        case 19: try { try decoder.decodeSingularBytesField(value: &_storage._alias) }()
        case 20: try { try decoder.decodeSingularBytesField(value: &_storage._ledgerID) }()
        case 21: try { try decoder.decodeSingularInt64Field(value: &_storage._ethereumNonce) }()
        case 22: try { try decoder.decodeSingularMessageField(value: &_storage._stakingInfo) }()
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
      try { if let v = _storage._accountID {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
      } }()
      if !_storage._contractAccountID.isEmpty {
        try visitor.visitSingularStringField(value: _storage._contractAccountID, fieldNumber: 2)
      }
      if _storage._deleted != false {
        try visitor.visitSingularBoolField(value: _storage._deleted, fieldNumber: 3)
      }
      try { if let v = _storage._proxyAccountID {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
      } }()
      if _storage._proxyReceived != 0 {
        try visitor.visitSingularInt64Field(value: _storage._proxyReceived, fieldNumber: 6)
      }
      try { if let v = _storage._key {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 7)
      } }()
      if _storage._balance != 0 {
        try visitor.visitSingularUInt64Field(value: _storage._balance, fieldNumber: 8)
      }
      if _storage._generateSendRecordThreshold != 0 {
        try visitor.visitSingularUInt64Field(value: _storage._generateSendRecordThreshold, fieldNumber: 9)
      }
      if _storage._generateReceiveRecordThreshold != 0 {
        try visitor.visitSingularUInt64Field(value: _storage._generateReceiveRecordThreshold, fieldNumber: 10)
      }
      if _storage._receiverSigRequired != false {
        try visitor.visitSingularBoolField(value: _storage._receiverSigRequired, fieldNumber: 11)
      }
      try { if let v = _storage._expirationTime {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 12)
      } }()
      try { if let v = _storage._autoRenewPeriod {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 13)
      } }()
      if !_storage._liveHashes.isEmpty {
        try visitor.visitRepeatedMessageField(value: _storage._liveHashes, fieldNumber: 14)
      }
      if !_storage._tokenRelationships.isEmpty {
        try visitor.visitRepeatedMessageField(value: _storage._tokenRelationships, fieldNumber: 15)
      }
      if !_storage._memo.isEmpty {
        try visitor.visitSingularStringField(value: _storage._memo, fieldNumber: 16)
      }
      if _storage._ownedNfts != 0 {
        try visitor.visitSingularInt64Field(value: _storage._ownedNfts, fieldNumber: 17)
      }
      if _storage._maxAutomaticTokenAssociations != 0 {
        try visitor.visitSingularInt32Field(value: _storage._maxAutomaticTokenAssociations, fieldNumber: 18)
      }
      if !_storage._alias.isEmpty {
        try visitor.visitSingularBytesField(value: _storage._alias, fieldNumber: 19)
      }
      if !_storage._ledgerID.isEmpty {
        try visitor.visitSingularBytesField(value: _storage._ledgerID, fieldNumber: 20)
      }
      if _storage._ethereumNonce != 0 {
        try visitor.visitSingularInt64Field(value: _storage._ethereumNonce, fieldNumber: 21)
      }
      try { if let v = _storage._stakingInfo {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 22)
      } }()
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_CryptoGetInfoResponse.AccountInfo, rhs: Proto_CryptoGetInfoResponse.AccountInfo) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._accountID != rhs_storage._accountID {return false}
        if _storage._contractAccountID != rhs_storage._contractAccountID {return false}
        if _storage._deleted != rhs_storage._deleted {return false}
        if _storage._proxyAccountID != rhs_storage._proxyAccountID {return false}
        if _storage._proxyReceived != rhs_storage._proxyReceived {return false}
        if _storage._key != rhs_storage._key {return false}
        if _storage._balance != rhs_storage._balance {return false}
        if _storage._generateSendRecordThreshold != rhs_storage._generateSendRecordThreshold {return false}
        if _storage._generateReceiveRecordThreshold != rhs_storage._generateReceiveRecordThreshold {return false}
        if _storage._receiverSigRequired != rhs_storage._receiverSigRequired {return false}
        if _storage._expirationTime != rhs_storage._expirationTime {return false}
        if _storage._autoRenewPeriod != rhs_storage._autoRenewPeriod {return false}
        if _storage._liveHashes != rhs_storage._liveHashes {return false}
        if _storage._tokenRelationships != rhs_storage._tokenRelationships {return false}
        if _storage._memo != rhs_storage._memo {return false}
        if _storage._ownedNfts != rhs_storage._ownedNfts {return false}
        if _storage._maxAutomaticTokenAssociations != rhs_storage._maxAutomaticTokenAssociations {return false}
        if _storage._alias != rhs_storage._alias {return false}
        if _storage._ledgerID != rhs_storage._ledgerID {return false}
        if _storage._ethereumNonce != rhs_storage._ethereumNonce {return false}
        if _storage._stakingInfo != rhs_storage._stakingInfo {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
