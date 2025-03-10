// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: state/file/file.proto
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
/// Representation of a Hedera Token Service file in the network Merkle tree.
///
/// As with all network entities, a file has a unique entity number, which is given along
/// with the network's shard and realm in the form of a shard.realm.number id.
public struct Proto_File: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///*
  /// The file's unique file identifier in the Merkle state.
  public var fileID: Proto_FileID {
    get {return _fileID ?? Proto_FileID()}
    set {_fileID = newValue}
  }
  /// Returns true if `fileID` has been explicitly set.
  public var hasFileID: Bool {return self._fileID != nil}
  /// Clears the value of `fileID`. Subsequent reads from it will return its default value.
  public mutating func clearFileID() {self._fileID = nil}

  ///*
  /// The file's consensus expiration time in seconds since the epoch.
  public var expirationSecond: Int64 = 0

  ///*
  /// All keys at the top level of a key list must sign to create, modify and delete the file.
  public var keys: Proto_KeyList {
    get {return _keys ?? Proto_KeyList()}
    set {_keys = newValue}
  }
  /// Returns true if `keys` has been explicitly set.
  public var hasKeys: Bool {return self._keys != nil}
  /// Clears the value of `keys`. Subsequent reads from it will return its default value.
  public mutating func clearKeys() {self._keys = nil}

  ///*
  /// The bytes that are the contents of the file
  public var contents: Data = Data()

  ///*
  /// The memo associated with the file (UTF-8 encoding max 100 bytes)
  public var memo: String = String()

  ///*
  /// Whether this file is deleted.
  public var deleted: Bool = false

  ///*
  /// The pre system delete expiration time in seconds
  public var preSystemDeleteExpirationSecond: Int64 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _fileID: Proto_FileID? = nil
  fileprivate var _keys: Proto_KeyList? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "proto"

extension Proto_File: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".File"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "file_id"),
    2: .standard(proto: "expiration_second"),
    3: .same(proto: "keys"),
    4: .same(proto: "contents"),
    5: .same(proto: "memo"),
    6: .same(proto: "deleted"),
    7: .standard(proto: "pre_system_delete_expiration_second"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._fileID) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.expirationSecond) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._keys) }()
      case 4: try { try decoder.decodeSingularBytesField(value: &self.contents) }()
      case 5: try { try decoder.decodeSingularStringField(value: &self.memo) }()
      case 6: try { try decoder.decodeSingularBoolField(value: &self.deleted) }()
      case 7: try { try decoder.decodeSingularInt64Field(value: &self.preSystemDeleteExpirationSecond) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._fileID {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    if self.expirationSecond != 0 {
      try visitor.visitSingularInt64Field(value: self.expirationSecond, fieldNumber: 2)
    }
    try { if let v = self._keys {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    } }()
    if !self.contents.isEmpty {
      try visitor.visitSingularBytesField(value: self.contents, fieldNumber: 4)
    }
    if !self.memo.isEmpty {
      try visitor.visitSingularStringField(value: self.memo, fieldNumber: 5)
    }
    if self.deleted != false {
      try visitor.visitSingularBoolField(value: self.deleted, fieldNumber: 6)
    }
    if self.preSystemDeleteExpirationSecond != 0 {
      try visitor.visitSingularInt64Field(value: self.preSystemDeleteExpirationSecond, fieldNumber: 7)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_File, rhs: Proto_File) -> Bool {
    if lhs._fileID != rhs._fileID {return false}
    if lhs.expirationSecond != rhs.expirationSecond {return false}
    if lhs._keys != rhs._keys {return false}
    if lhs.contents != rhs.contents {return false}
    if lhs.memo != rhs.memo {return false}
    if lhs.deleted != rhs.deleted {return false}
    if lhs.preSystemDeleteExpirationSecond != rhs.preSystemDeleteExpirationSecond {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
