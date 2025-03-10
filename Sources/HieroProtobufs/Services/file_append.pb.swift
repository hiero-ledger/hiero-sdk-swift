// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: file_append.proto
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
/// Append the given contents to the end of the specified file. If a file is too big to create with a
/// single FileCreateTransaction, then it can be created with the first part of its contents, and
/// then appended as many times as necessary to create the entire file. This transaction must be
/// signed by all initial M-of-M KeyList keys. If keys contains additional KeyList or ThresholdKey
/// then M-of-M secondary KeyList or ThresholdKey signing requirements must be meet. 
public struct Proto_FileAppendTransactionBody: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///*
  /// The file to which the bytes will be appended
  public var fileID: Proto_FileID {
    get {return _fileID ?? Proto_FileID()}
    set {_fileID = newValue}
  }
  /// Returns true if `fileID` has been explicitly set.
  public var hasFileID: Bool {return self._fileID != nil}
  /// Clears the value of `fileID`. Subsequent reads from it will return its default value.
  public mutating func clearFileID() {self._fileID = nil}

  ///*
  /// The bytes that will be appended to the end of the specified file
  public var contents: Data = Data()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _fileID: Proto_FileID? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "proto"

extension Proto_FileAppendTransactionBody: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".FileAppendTransactionBody"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    2: .same(proto: "fileID"),
    4: .same(proto: "contents"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 2: try { try decoder.decodeSingularMessageField(value: &self._fileID) }()
      case 4: try { try decoder.decodeSingularBytesField(value: &self.contents) }()
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
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    if !self.contents.isEmpty {
      try visitor.visitSingularBytesField(value: self.contents, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Proto_FileAppendTransactionBody, rhs: Proto_FileAppendTransactionBody) -> Bool {
    if lhs._fileID != rhs._fileID {return false}
    if lhs.contents != rhs.contents {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
