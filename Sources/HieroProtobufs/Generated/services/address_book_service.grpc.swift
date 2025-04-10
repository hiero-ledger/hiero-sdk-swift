//
// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the protocol buffer compiler.
// Source: services/address_book_service.proto
//
import GRPC
import NIO
import NIOConcurrencyHelpers
import SwiftProtobuf


///*
/// The Address Book service provides the ability for Hedera network node
/// administrators to add, update, and remove consensus nodes. This addition,
/// update, or removal of a consensus node requires governing council approval,
/// but each node operator may update their own operational attributes without
/// additional approval, reducing overhead for routine operations.
///
/// Most operations are `privileged operations` and require governing council
/// approval.
///
/// ### For a node creation transaction.
/// - The node operator SHALL create a `createNode` transaction.
///    - The node operator MUST sign this transaction with the `Key`
///      set as the `admin_key` for the new `Node`.
///    - The node operator SHALL deliver the signed transaction to the Hedera
///      council representative.
///    - The Hedera council representative SHALL arrange for council members to
///      review and sign the transaction.
///    - Once sufficient council members have signed the transaction, the
///      Hedera council representative SHALL submit the transaction to the
///      network.
/// - Upon receipt of a valid and signed node creation transaction the network
///   software SHALL
///    - Validate the threshold signature for the Hedera governing council
///    - Validate the signature of the `Key` provided as the new `admin_key`
///      for the `Node`.
///    - Create the new node in state, this new node SHALL NOT be active in the
///      network at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration and bring the
///      new node to an active status within the network. The node to be added
///      SHALL be active in the network following this upgrade.
///
/// ### For a node deletion transaction.
/// - The node operator or Hedera council representative SHALL create a
///   `deleteNode` transaction.
///    - If the node operator creates the transaction
///       - The node operator MUST sign this transaction with the `Key`
///         set as the `admin_key` for the existing `Node`.
///       - The node operator SHALL deliver the signed transaction to the Hedera
///         council representative.
///    - The Hedera council representative SHALL arrange for council members to
///      review and sign the transaction.
///    - Once sufficient council members have signed the transaction, the
///      Hedera council representative SHALL submit the transaction to the
///      network.
/// - Upon receipt of a valid and signed node deletion transaction the network
///   software SHALL
///    - Validate the signature for the Hedera governing council
///    - Remove the existing node from network state. The node SHALL still
///      be active in the network at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration and remove the
///      node to be deleted from the network. The node to be deleted SHALL NOT
///      be active in the network following this upgrade.
///
/// ### For a node update transaction.
/// - The node operator SHALL create an `updateNode` transaction.
///    - The node operator MUST sign this transaction with the active `key`
///      assigned as the `admin_key`.
///    - The node operator SHALL submit the transaction to the
///      network.  Hedera council approval SHALL NOT be sought for this
///      transaction
/// - Upon receipt of a valid and signed node update transaction the network
///   software SHALL
///    - If the transaction modifies the value of the "node account",
///       - Validate the signature of the active `key` for the account
///         assigned as the _current_ "node account".
///       - Validate the signature of the active `key` for the account to be
///         assigned as the _new_ "node account".
///    - Modify the node information held in network state with the changes
///      requested in the update transaction. The node changes SHALL NOT be
///      applied to network configuration, and SHALL NOT affect network
///      operation at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration according to the
///      modified information in network state. The requested changes SHALL
///      affect network operation following this upgrade.
///
/// Usage: instantiate `Proto_AddressBookServiceClient`, then call methods of this protocol to make API calls.
public protocol Proto_AddressBookServiceClientProtocol: GRPCClient {
  var serviceName: String { get }
  var interceptors: Proto_AddressBookServiceClientInterceptorFactoryProtocol? { get }

  func createNode(
    _ request: Proto_Transaction,
    callOptions: CallOptions?
  ) -> UnaryCall<Proto_Transaction, Proto_TransactionResponse>

  func deleteNode(
    _ request: Proto_Transaction,
    callOptions: CallOptions?
  ) -> UnaryCall<Proto_Transaction, Proto_TransactionResponse>

  func updateNode(
    _ request: Proto_Transaction,
    callOptions: CallOptions?
  ) -> UnaryCall<Proto_Transaction, Proto_TransactionResponse>
}

extension Proto_AddressBookServiceClientProtocol {
  public var serviceName: String {
    return "proto.AddressBookService"
  }

  ///*
  /// A transaction to create a new consensus node in the network
  /// address book.
  /// <p>
  /// This transaction, once complete, SHALL add a new consensus node to the
  /// network state.<br/>
  /// The new consensus node SHALL remain in state, but SHALL NOT participate
  /// in network consensus until the network updates the network configuration.
  /// <p>
  /// Hedera governing council authorization is REQUIRED for this transaction.
  ///
  /// - Parameters:
  ///   - request: Request to send to createNode.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  public func createNode(
    _ request: Proto_Transaction,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Proto_Transaction, Proto_TransactionResponse> {
    return self.makeUnaryCall(
      path: Proto_AddressBookServiceClientMetadata.Methods.createNode.path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makecreateNodeInterceptors() ?? []
    )
  }

  ///*
  /// A transaction to remove a consensus node from the network address
  /// book.
  /// <p>
  /// This transaction, once complete, SHALL remove the identified consensus
  /// node from the network state.
  /// <p>
  /// Hedera governing council authorization is REQUIRED for this transaction.
  ///
  /// - Parameters:
  ///   - request: Request to send to deleteNode.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  public func deleteNode(
    _ request: Proto_Transaction,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Proto_Transaction, Proto_TransactionResponse> {
    return self.makeUnaryCall(
      path: Proto_AddressBookServiceClientMetadata.Methods.deleteNode.path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makedeleteNodeInterceptors() ?? []
    )
  }

  ///*
  /// A transaction to update an existing consensus node from the network
  /// address book.
  /// <p>
  /// This transaction, once complete, SHALL modify the identified consensus
  /// node state as requested.
  /// <p>
  /// This transaction is authorized by the node operator
  ///
  /// - Parameters:
  ///   - request: Request to send to updateNode.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  public func updateNode(
    _ request: Proto_Transaction,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Proto_Transaction, Proto_TransactionResponse> {
    return self.makeUnaryCall(
      path: Proto_AddressBookServiceClientMetadata.Methods.updateNode.path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeupdateNodeInterceptors() ?? []
    )
  }
}

@available(*, deprecated)
extension Proto_AddressBookServiceClient: @unchecked Sendable {}

@available(*, deprecated, renamed: "Proto_AddressBookServiceNIOClient")
public final class Proto_AddressBookServiceClient: Proto_AddressBookServiceClientProtocol {
  private let lock = Lock()
  private var _defaultCallOptions: CallOptions
  private var _interceptors: Proto_AddressBookServiceClientInterceptorFactoryProtocol?
  public let channel: GRPCChannel
  public var defaultCallOptions: CallOptions {
    get { self.lock.withLock { return self._defaultCallOptions } }
    set { self.lock.withLockVoid { self._defaultCallOptions = newValue } }
  }
  public var interceptors: Proto_AddressBookServiceClientInterceptorFactoryProtocol? {
    get { self.lock.withLock { return self._interceptors } }
    set { self.lock.withLockVoid { self._interceptors = newValue } }
  }

  /// Creates a client for the proto.AddressBookService service.
  ///
  /// - Parameters:
  ///   - channel: `GRPCChannel` to the service host.
  ///   - defaultCallOptions: Options to use for each service call if the user doesn't provide them.
  ///   - interceptors: A factory providing interceptors for each RPC.
  public init(
    channel: GRPCChannel,
    defaultCallOptions: CallOptions = CallOptions(),
    interceptors: Proto_AddressBookServiceClientInterceptorFactoryProtocol? = nil
  ) {
    self.channel = channel
    self._defaultCallOptions = defaultCallOptions
    self._interceptors = interceptors
  }
}

public struct Proto_AddressBookServiceNIOClient: Proto_AddressBookServiceClientProtocol {
  public var channel: GRPCChannel
  public var defaultCallOptions: CallOptions
  public var interceptors: Proto_AddressBookServiceClientInterceptorFactoryProtocol?

  /// Creates a client for the proto.AddressBookService service.
  ///
  /// - Parameters:
  ///   - channel: `GRPCChannel` to the service host.
  ///   - defaultCallOptions: Options to use for each service call if the user doesn't provide them.
  ///   - interceptors: A factory providing interceptors for each RPC.
  public init(
    channel: GRPCChannel,
    defaultCallOptions: CallOptions = CallOptions(),
    interceptors: Proto_AddressBookServiceClientInterceptorFactoryProtocol? = nil
  ) {
    self.channel = channel
    self.defaultCallOptions = defaultCallOptions
    self.interceptors = interceptors
  }
}

///*
/// The Address Book service provides the ability for Hedera network node
/// administrators to add, update, and remove consensus nodes. This addition,
/// update, or removal of a consensus node requires governing council approval,
/// but each node operator may update their own operational attributes without
/// additional approval, reducing overhead for routine operations.
///
/// Most operations are `privileged operations` and require governing council
/// approval.
///
/// ### For a node creation transaction.
/// - The node operator SHALL create a `createNode` transaction.
///    - The node operator MUST sign this transaction with the `Key`
///      set as the `admin_key` for the new `Node`.
///    - The node operator SHALL deliver the signed transaction to the Hedera
///      council representative.
///    - The Hedera council representative SHALL arrange for council members to
///      review and sign the transaction.
///    - Once sufficient council members have signed the transaction, the
///      Hedera council representative SHALL submit the transaction to the
///      network.
/// - Upon receipt of a valid and signed node creation transaction the network
///   software SHALL
///    - Validate the threshold signature for the Hedera governing council
///    - Validate the signature of the `Key` provided as the new `admin_key`
///      for the `Node`.
///    - Create the new node in state, this new node SHALL NOT be active in the
///      network at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration and bring the
///      new node to an active status within the network. The node to be added
///      SHALL be active in the network following this upgrade.
///
/// ### For a node deletion transaction.
/// - The node operator or Hedera council representative SHALL create a
///   `deleteNode` transaction.
///    - If the node operator creates the transaction
///       - The node operator MUST sign this transaction with the `Key`
///         set as the `admin_key` for the existing `Node`.
///       - The node operator SHALL deliver the signed transaction to the Hedera
///         council representative.
///    - The Hedera council representative SHALL arrange for council members to
///      review and sign the transaction.
///    - Once sufficient council members have signed the transaction, the
///      Hedera council representative SHALL submit the transaction to the
///      network.
/// - Upon receipt of a valid and signed node deletion transaction the network
///   software SHALL
///    - Validate the signature for the Hedera governing council
///    - Remove the existing node from network state. The node SHALL still
///      be active in the network at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration and remove the
///      node to be deleted from the network. The node to be deleted SHALL NOT
///      be active in the network following this upgrade.
///
/// ### For a node update transaction.
/// - The node operator SHALL create an `updateNode` transaction.
///    - The node operator MUST sign this transaction with the active `key`
///      assigned as the `admin_key`.
///    - The node operator SHALL submit the transaction to the
///      network.  Hedera council approval SHALL NOT be sought for this
///      transaction
/// - Upon receipt of a valid and signed node update transaction the network
///   software SHALL
///    - If the transaction modifies the value of the "node account",
///       - Validate the signature of the active `key` for the account
///         assigned as the _current_ "node account".
///       - Validate the signature of the active `key` for the account to be
///         assigned as the _new_ "node account".
///    - Modify the node information held in network state with the changes
///      requested in the update transaction. The node changes SHALL NOT be
///      applied to network configuration, and SHALL NOT affect network
///      operation at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration according to the
///      modified information in network state. The requested changes SHALL
///      affect network operation following this upgrade.
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol Proto_AddressBookServiceAsyncClientProtocol: GRPCClient {
  static var serviceDescriptor: GRPCServiceDescriptor { get }
  var interceptors: Proto_AddressBookServiceClientInterceptorFactoryProtocol? { get }

  func makeCreateNodeCall(
    _ request: Proto_Transaction,
    callOptions: CallOptions?
  ) -> GRPCAsyncUnaryCall<Proto_Transaction, Proto_TransactionResponse>

  func makeDeleteNodeCall(
    _ request: Proto_Transaction,
    callOptions: CallOptions?
  ) -> GRPCAsyncUnaryCall<Proto_Transaction, Proto_TransactionResponse>

  func makeUpdateNodeCall(
    _ request: Proto_Transaction,
    callOptions: CallOptions?
  ) -> GRPCAsyncUnaryCall<Proto_Transaction, Proto_TransactionResponse>
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Proto_AddressBookServiceAsyncClientProtocol {
  public static var serviceDescriptor: GRPCServiceDescriptor {
    return Proto_AddressBookServiceClientMetadata.serviceDescriptor
  }

  public var interceptors: Proto_AddressBookServiceClientInterceptorFactoryProtocol? {
    return nil
  }

  public func makeCreateNodeCall(
    _ request: Proto_Transaction,
    callOptions: CallOptions? = nil
  ) -> GRPCAsyncUnaryCall<Proto_Transaction, Proto_TransactionResponse> {
    return self.makeAsyncUnaryCall(
      path: Proto_AddressBookServiceClientMetadata.Methods.createNode.path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makecreateNodeInterceptors() ?? []
    )
  }

  public func makeDeleteNodeCall(
    _ request: Proto_Transaction,
    callOptions: CallOptions? = nil
  ) -> GRPCAsyncUnaryCall<Proto_Transaction, Proto_TransactionResponse> {
    return self.makeAsyncUnaryCall(
      path: Proto_AddressBookServiceClientMetadata.Methods.deleteNode.path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makedeleteNodeInterceptors() ?? []
    )
  }

  public func makeUpdateNodeCall(
    _ request: Proto_Transaction,
    callOptions: CallOptions? = nil
  ) -> GRPCAsyncUnaryCall<Proto_Transaction, Proto_TransactionResponse> {
    return self.makeAsyncUnaryCall(
      path: Proto_AddressBookServiceClientMetadata.Methods.updateNode.path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeupdateNodeInterceptors() ?? []
    )
  }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Proto_AddressBookServiceAsyncClientProtocol {
  public func createNode(
    _ request: Proto_Transaction,
    callOptions: CallOptions? = nil
  ) async throws -> Proto_TransactionResponse {
    return try await self.performAsyncUnaryCall(
      path: Proto_AddressBookServiceClientMetadata.Methods.createNode.path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makecreateNodeInterceptors() ?? []
    )
  }

  public func deleteNode(
    _ request: Proto_Transaction,
    callOptions: CallOptions? = nil
  ) async throws -> Proto_TransactionResponse {
    return try await self.performAsyncUnaryCall(
      path: Proto_AddressBookServiceClientMetadata.Methods.deleteNode.path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makedeleteNodeInterceptors() ?? []
    )
  }

  public func updateNode(
    _ request: Proto_Transaction,
    callOptions: CallOptions? = nil
  ) async throws -> Proto_TransactionResponse {
    return try await self.performAsyncUnaryCall(
      path: Proto_AddressBookServiceClientMetadata.Methods.updateNode.path,
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeupdateNodeInterceptors() ?? []
    )
  }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public struct Proto_AddressBookServiceAsyncClient: Proto_AddressBookServiceAsyncClientProtocol {
  public var channel: GRPCChannel
  public var defaultCallOptions: CallOptions
  public var interceptors: Proto_AddressBookServiceClientInterceptorFactoryProtocol?

  public init(
    channel: GRPCChannel,
    defaultCallOptions: CallOptions = CallOptions(),
    interceptors: Proto_AddressBookServiceClientInterceptorFactoryProtocol? = nil
  ) {
    self.channel = channel
    self.defaultCallOptions = defaultCallOptions
    self.interceptors = interceptors
  }
}

public protocol Proto_AddressBookServiceClientInterceptorFactoryProtocol: Sendable {

  /// - Returns: Interceptors to use when invoking 'createNode'.
  func makecreateNodeInterceptors() -> [ClientInterceptor<Proto_Transaction, Proto_TransactionResponse>]

  /// - Returns: Interceptors to use when invoking 'deleteNode'.
  func makedeleteNodeInterceptors() -> [ClientInterceptor<Proto_Transaction, Proto_TransactionResponse>]

  /// - Returns: Interceptors to use when invoking 'updateNode'.
  func makeupdateNodeInterceptors() -> [ClientInterceptor<Proto_Transaction, Proto_TransactionResponse>]
}

public enum Proto_AddressBookServiceClientMetadata {
  public static let serviceDescriptor = GRPCServiceDescriptor(
    name: "AddressBookService",
    fullName: "proto.AddressBookService",
    methods: [
      Proto_AddressBookServiceClientMetadata.Methods.createNode,
      Proto_AddressBookServiceClientMetadata.Methods.deleteNode,
      Proto_AddressBookServiceClientMetadata.Methods.updateNode,
    ]
  )

  public enum Methods {
    public static let createNode = GRPCMethodDescriptor(
      name: "createNode",
      path: "/proto.AddressBookService/createNode",
      type: GRPCCallType.unary
    )

    public static let deleteNode = GRPCMethodDescriptor(
      name: "deleteNode",
      path: "/proto.AddressBookService/deleteNode",
      type: GRPCCallType.unary
    )

    public static let updateNode = GRPCMethodDescriptor(
      name: "updateNode",
      path: "/proto.AddressBookService/updateNode",
      type: GRPCCallType.unary
    )
  }
}

///*
/// The Address Book service provides the ability for Hedera network node
/// administrators to add, update, and remove consensus nodes. This addition,
/// update, or removal of a consensus node requires governing council approval,
/// but each node operator may update their own operational attributes without
/// additional approval, reducing overhead for routine operations.
///
/// Most operations are `privileged operations` and require governing council
/// approval.
///
/// ### For a node creation transaction.
/// - The node operator SHALL create a `createNode` transaction.
///    - The node operator MUST sign this transaction with the `Key`
///      set as the `admin_key` for the new `Node`.
///    - The node operator SHALL deliver the signed transaction to the Hedera
///      council representative.
///    - The Hedera council representative SHALL arrange for council members to
///      review and sign the transaction.
///    - Once sufficient council members have signed the transaction, the
///      Hedera council representative SHALL submit the transaction to the
///      network.
/// - Upon receipt of a valid and signed node creation transaction the network
///   software SHALL
///    - Validate the threshold signature for the Hedera governing council
///    - Validate the signature of the `Key` provided as the new `admin_key`
///      for the `Node`.
///    - Create the new node in state, this new node SHALL NOT be active in the
///      network at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration and bring the
///      new node to an active status within the network. The node to be added
///      SHALL be active in the network following this upgrade.
///
/// ### For a node deletion transaction.
/// - The node operator or Hedera council representative SHALL create a
///   `deleteNode` transaction.
///    - If the node operator creates the transaction
///       - The node operator MUST sign this transaction with the `Key`
///         set as the `admin_key` for the existing `Node`.
///       - The node operator SHALL deliver the signed transaction to the Hedera
///         council representative.
///    - The Hedera council representative SHALL arrange for council members to
///      review and sign the transaction.
///    - Once sufficient council members have signed the transaction, the
///      Hedera council representative SHALL submit the transaction to the
///      network.
/// - Upon receipt of a valid and signed node deletion transaction the network
///   software SHALL
///    - Validate the signature for the Hedera governing council
///    - Remove the existing node from network state. The node SHALL still
///      be active in the network at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration and remove the
///      node to be deleted from the network. The node to be deleted SHALL NOT
///      be active in the network following this upgrade.
///
/// ### For a node update transaction.
/// - The node operator SHALL create an `updateNode` transaction.
///    - The node operator MUST sign this transaction with the active `key`
///      assigned as the `admin_key`.
///    - The node operator SHALL submit the transaction to the
///      network.  Hedera council approval SHALL NOT be sought for this
///      transaction
/// - Upon receipt of a valid and signed node update transaction the network
///   software SHALL
///    - If the transaction modifies the value of the "node account",
///       - Validate the signature of the active `key` for the account
///         assigned as the _current_ "node account".
///       - Validate the signature of the active `key` for the account to be
///         assigned as the _new_ "node account".
///    - Modify the node information held in network state with the changes
///      requested in the update transaction. The node changes SHALL NOT be
///      applied to network configuration, and SHALL NOT affect network
///      operation at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration according to the
///      modified information in network state. The requested changes SHALL
///      affect network operation following this upgrade.
///
/// To build a server, implement a class that conforms to this protocol.
public protocol Proto_AddressBookServiceProvider: CallHandlerProvider {
  var interceptors: Proto_AddressBookServiceServerInterceptorFactoryProtocol? { get }

  ///*
  /// A transaction to create a new consensus node in the network
  /// address book.
  /// <p>
  /// This transaction, once complete, SHALL add a new consensus node to the
  /// network state.<br/>
  /// The new consensus node SHALL remain in state, but SHALL NOT participate
  /// in network consensus until the network updates the network configuration.
  /// <p>
  /// Hedera governing council authorization is REQUIRED for this transaction.
  func createNode(request: Proto_Transaction, context: StatusOnlyCallContext) -> EventLoopFuture<Proto_TransactionResponse>

  ///*
  /// A transaction to remove a consensus node from the network address
  /// book.
  /// <p>
  /// This transaction, once complete, SHALL remove the identified consensus
  /// node from the network state.
  /// <p>
  /// Hedera governing council authorization is REQUIRED for this transaction.
  func deleteNode(request: Proto_Transaction, context: StatusOnlyCallContext) -> EventLoopFuture<Proto_TransactionResponse>

  ///*
  /// A transaction to update an existing consensus node from the network
  /// address book.
  /// <p>
  /// This transaction, once complete, SHALL modify the identified consensus
  /// node state as requested.
  /// <p>
  /// This transaction is authorized by the node operator
  func updateNode(request: Proto_Transaction, context: StatusOnlyCallContext) -> EventLoopFuture<Proto_TransactionResponse>
}

extension Proto_AddressBookServiceProvider {
  public var serviceName: Substring {
    return Proto_AddressBookServiceServerMetadata.serviceDescriptor.fullName[...]
  }

  /// Determines, calls and returns the appropriate request handler, depending on the request's method.
  /// Returns nil for methods not handled by this service.
  public func handle(
    method name: Substring,
    context: CallHandlerContext
  ) -> GRPCServerHandlerProtocol? {
    switch name {
    case "createNode":
      return UnaryServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<Proto_Transaction>(),
        responseSerializer: ProtobufSerializer<Proto_TransactionResponse>(),
        interceptors: self.interceptors?.makecreateNodeInterceptors() ?? [],
        userFunction: self.createNode(request:context:)
      )

    case "deleteNode":
      return UnaryServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<Proto_Transaction>(),
        responseSerializer: ProtobufSerializer<Proto_TransactionResponse>(),
        interceptors: self.interceptors?.makedeleteNodeInterceptors() ?? [],
        userFunction: self.deleteNode(request:context:)
      )

    case "updateNode":
      return UnaryServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<Proto_Transaction>(),
        responseSerializer: ProtobufSerializer<Proto_TransactionResponse>(),
        interceptors: self.interceptors?.makeupdateNodeInterceptors() ?? [],
        userFunction: self.updateNode(request:context:)
      )

    default:
      return nil
    }
  }
}

///*
/// The Address Book service provides the ability for Hedera network node
/// administrators to add, update, and remove consensus nodes. This addition,
/// update, or removal of a consensus node requires governing council approval,
/// but each node operator may update their own operational attributes without
/// additional approval, reducing overhead for routine operations.
///
/// Most operations are `privileged operations` and require governing council
/// approval.
///
/// ### For a node creation transaction.
/// - The node operator SHALL create a `createNode` transaction.
///    - The node operator MUST sign this transaction with the `Key`
///      set as the `admin_key` for the new `Node`.
///    - The node operator SHALL deliver the signed transaction to the Hedera
///      council representative.
///    - The Hedera council representative SHALL arrange for council members to
///      review and sign the transaction.
///    - Once sufficient council members have signed the transaction, the
///      Hedera council representative SHALL submit the transaction to the
///      network.
/// - Upon receipt of a valid and signed node creation transaction the network
///   software SHALL
///    - Validate the threshold signature for the Hedera governing council
///    - Validate the signature of the `Key` provided as the new `admin_key`
///      for the `Node`.
///    - Create the new node in state, this new node SHALL NOT be active in the
///      network at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration and bring the
///      new node to an active status within the network. The node to be added
///      SHALL be active in the network following this upgrade.
///
/// ### For a node deletion transaction.
/// - The node operator or Hedera council representative SHALL create a
///   `deleteNode` transaction.
///    - If the node operator creates the transaction
///       - The node operator MUST sign this transaction with the `Key`
///         set as the `admin_key` for the existing `Node`.
///       - The node operator SHALL deliver the signed transaction to the Hedera
///         council representative.
///    - The Hedera council representative SHALL arrange for council members to
///      review and sign the transaction.
///    - Once sufficient council members have signed the transaction, the
///      Hedera council representative SHALL submit the transaction to the
///      network.
/// - Upon receipt of a valid and signed node deletion transaction the network
///   software SHALL
///    - Validate the signature for the Hedera governing council
///    - Remove the existing node from network state. The node SHALL still
///      be active in the network at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration and remove the
///      node to be deleted from the network. The node to be deleted SHALL NOT
///      be active in the network following this upgrade.
///
/// ### For a node update transaction.
/// - The node operator SHALL create an `updateNode` transaction.
///    - The node operator MUST sign this transaction with the active `key`
///      assigned as the `admin_key`.
///    - The node operator SHALL submit the transaction to the
///      network.  Hedera council approval SHALL NOT be sought for this
///      transaction
/// - Upon receipt of a valid and signed node update transaction the network
///   software SHALL
///    - If the transaction modifies the value of the "node account",
///       - Validate the signature of the active `key` for the account
///         assigned as the _current_ "node account".
///       - Validate the signature of the active `key` for the account to be
///         assigned as the _new_ "node account".
///    - Modify the node information held in network state with the changes
///      requested in the update transaction. The node changes SHALL NOT be
///      applied to network configuration, and SHALL NOT affect network
///      operation at this time.
///    - When executing the next `freeze` transaction with `freeze_type` set to
///      `PREPARE_UPGRADE`, update network configuration according to the
///      modified information in network state. The requested changes SHALL
///      affect network operation following this upgrade.
///
/// To implement a server, implement an object which conforms to this protocol.
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol Proto_AddressBookServiceAsyncProvider: CallHandlerProvider, Sendable {
  static var serviceDescriptor: GRPCServiceDescriptor { get }
  var interceptors: Proto_AddressBookServiceServerInterceptorFactoryProtocol? { get }

  ///*
  /// A transaction to create a new consensus node in the network
  /// address book.
  /// <p>
  /// This transaction, once complete, SHALL add a new consensus node to the
  /// network state.<br/>
  /// The new consensus node SHALL remain in state, but SHALL NOT participate
  /// in network consensus until the network updates the network configuration.
  /// <p>
  /// Hedera governing council authorization is REQUIRED for this transaction.
  func createNode(
    request: Proto_Transaction,
    context: GRPCAsyncServerCallContext
  ) async throws -> Proto_TransactionResponse

  ///*
  /// A transaction to remove a consensus node from the network address
  /// book.
  /// <p>
  /// This transaction, once complete, SHALL remove the identified consensus
  /// node from the network state.
  /// <p>
  /// Hedera governing council authorization is REQUIRED for this transaction.
  func deleteNode(
    request: Proto_Transaction,
    context: GRPCAsyncServerCallContext
  ) async throws -> Proto_TransactionResponse

  ///*
  /// A transaction to update an existing consensus node from the network
  /// address book.
  /// <p>
  /// This transaction, once complete, SHALL modify the identified consensus
  /// node state as requested.
  /// <p>
  /// This transaction is authorized by the node operator
  func updateNode(
    request: Proto_Transaction,
    context: GRPCAsyncServerCallContext
  ) async throws -> Proto_TransactionResponse
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Proto_AddressBookServiceAsyncProvider {
  public static var serviceDescriptor: GRPCServiceDescriptor {
    return Proto_AddressBookServiceServerMetadata.serviceDescriptor
  }

  public var serviceName: Substring {
    return Proto_AddressBookServiceServerMetadata.serviceDescriptor.fullName[...]
  }

  public var interceptors: Proto_AddressBookServiceServerInterceptorFactoryProtocol? {
    return nil
  }

  public func handle(
    method name: Substring,
    context: CallHandlerContext
  ) -> GRPCServerHandlerProtocol? {
    switch name {
    case "createNode":
      return GRPCAsyncServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<Proto_Transaction>(),
        responseSerializer: ProtobufSerializer<Proto_TransactionResponse>(),
        interceptors: self.interceptors?.makecreateNodeInterceptors() ?? [],
        wrapping: { try await self.createNode(request: $0, context: $1) }
      )

    case "deleteNode":
      return GRPCAsyncServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<Proto_Transaction>(),
        responseSerializer: ProtobufSerializer<Proto_TransactionResponse>(),
        interceptors: self.interceptors?.makedeleteNodeInterceptors() ?? [],
        wrapping: { try await self.deleteNode(request: $0, context: $1) }
      )

    case "updateNode":
      return GRPCAsyncServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<Proto_Transaction>(),
        responseSerializer: ProtobufSerializer<Proto_TransactionResponse>(),
        interceptors: self.interceptors?.makeupdateNodeInterceptors() ?? [],
        wrapping: { try await self.updateNode(request: $0, context: $1) }
      )

    default:
      return nil
    }
  }
}

public protocol Proto_AddressBookServiceServerInterceptorFactoryProtocol: Sendable {

  /// - Returns: Interceptors to use when handling 'createNode'.
  ///   Defaults to calling `self.makeInterceptors()`.
  func makecreateNodeInterceptors() -> [ServerInterceptor<Proto_Transaction, Proto_TransactionResponse>]

  /// - Returns: Interceptors to use when handling 'deleteNode'.
  ///   Defaults to calling `self.makeInterceptors()`.
  func makedeleteNodeInterceptors() -> [ServerInterceptor<Proto_Transaction, Proto_TransactionResponse>]

  /// - Returns: Interceptors to use when handling 'updateNode'.
  ///   Defaults to calling `self.makeInterceptors()`.
  func makeupdateNodeInterceptors() -> [ServerInterceptor<Proto_Transaction, Proto_TransactionResponse>]
}

public enum Proto_AddressBookServiceServerMetadata {
  public static let serviceDescriptor = GRPCServiceDescriptor(
    name: "AddressBookService",
    fullName: "proto.AddressBookService",
    methods: [
      Proto_AddressBookServiceServerMetadata.Methods.createNode,
      Proto_AddressBookServiceServerMetadata.Methods.deleteNode,
      Proto_AddressBookServiceServerMetadata.Methods.updateNode,
    ]
  )

  public enum Methods {
    public static let createNode = GRPCMethodDescriptor(
      name: "createNode",
      path: "/proto.AddressBookService/createNode",
      type: GRPCCallType.unary
    )

    public static let deleteNode = GRPCMethodDescriptor(
      name: "deleteNode",
      path: "/proto.AddressBookService/deleteNode",
      type: GRPCCallType.unary
    )

    public static let updateNode = GRPCMethodDescriptor(
      name: "updateNode",
      path: "/proto.AddressBookService/updateNode",
      type: GRPCCallType.unary
    )
  }
}
