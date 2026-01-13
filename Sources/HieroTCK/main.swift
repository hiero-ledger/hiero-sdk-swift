// SPDX-License-Identifier: Apache-2.0

import Vapor

@testable import Hiero

/// Entry point: Initializes and runs the TCK JSON-RPC server.
let server = TCKServer()
try TCKServer.main()

/// Test Compatibility Kit (TCK) JSON-RPC server.
///
/// Handles routing and execution of JSON-RPC methods using Vapor.
/// Designed to be deterministic and consistent with the Hiero SDK behaviors under test.
internal class TCKServer {

    // MARK: - Entry Point

    /// Main entry point for the server. Sets up environment, configures logging and routes, and starts the HTTP server.
    internal static func main() throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = Application(env)
        defer { app.shutdown() }

        app.http.server.configuration.port = 8544
        app.routes.defaultMaxBodySize = "10mb"
        app.post { req -> Response in
            var jsonRpcRequest: JSONRequest

            // Decode request body into JSON-RPC object, or return error response if invalid.
            do {
                jsonRpcRequest = try req.content.decode(JSONRequest.self)
            } catch let error as JSONError {
                return try encodeJsonRpcResponseToHttpResponse(jsonResponse: JSONResponse(id: nil, error: error))
            } catch {
                print("Request decode error (not JSONError): \(type(of: error)) - \(error)")
                return try encodeJsonRpcResponseToHttpResponse(
                    jsonResponse: JSONResponse(id: nil, error: JSONError.parseError("Parse error: \(error)")))
            }

            // Process the JSON-RPC request and encode the response.
            let response = await server.processRequest(request: jsonRpcRequest)
            return try encodeJsonRpcResponseToHttpResponse(jsonResponse: response)
        }

        try app.run()
    }

    // MARK: - Request Routing

    /// Processes a JSON-RPC request and returns a corresponding response.
    ///
    /// Routes based on the `method` field of the request and delegates to the appropriate service layer.
    private func processRequest(request: JSONRequest) async -> JSONResponse {
        do {
            let jsonRpcResponse: JSONObject
            let method = JSONRPCMethod.method(named: request.method)

            switch method {

            // MARK: - AccountService Methods

            case .approveAllowance:
                jsonRpcResponse = try await AccountService.approveAllowance(
                    from: ApproveAllowanceParams(request: request))
            case .createAccount:
                jsonRpcResponse = try await AccountService.createAccount(from: CreateAccountParams(request: request))
            case .deleteAccount:
                jsonRpcResponse = try await AccountService.deleteAccount(from: DeleteAccountParams(request: request))
            case .deleteAllowance:
                jsonRpcResponse = try await AccountService.deleteAllowance(
                    from: DeleteAllowanceParams(request: request))
            case .transferCrypto:
                jsonRpcResponse = try await AccountService.transferCrypto(from: TransferCryptoParams(request: request))
            case .updateAccount:
                jsonRpcResponse = try await AccountService.updateAccount(from: UpdateAccountParams(request: request))

            // MARK: - ContractService Methods

            case .contractByteCodeQuery:
                jsonRpcResponse = try await ContractService.contractByteCodeQuery(
                    from: ContractByteCodeQueryParams(request: request))
            case .contractCallQuery:
                jsonRpcResponse = try await ContractService.contractCallQuery(
                    from: ContractCallQueryParams(request: request))
            case .contractInfoQuery:
                jsonRpcResponse = try await ContractService.contractInfoQuery(from: ContractInfoQueryParams(request: request))
            case .createContract:
                jsonRpcResponse = try await ContractService.createContract(from: CreateContractParams(request: request))
            case .createEthereumTransaction:
                jsonRpcResponse = try await ContractService.createEthereumTransaction(
                    from: CreateEthereumTransactionParams(request: request))
            case .deleteContract:
                jsonRpcResponse = try await ContractService.deleteContract(from: DeleteContractParams(request: request))
            case .executeContract:
                jsonRpcResponse = try await ContractService.executeContract(
                    from: ExecuteContractParams(request: request))
            case .updateContract:
                jsonRpcResponse = try await ContractService.updateContract(from: UpdateContractParams(request: request))

            // MARK: - FileService Methods

            case .appendFile:
                jsonRpcResponse = try await FileService.appendFile(from: AppendFileParams(request: request))
            case .createFile:
                jsonRpcResponse = try await FileService.createFile(from: CreateFileParams(request: request))
            case .deleteFile:
                jsonRpcResponse = try await FileService.deleteFile(from: DeleteFileParams(request: request))
            case .updateFile:
                jsonRpcResponse = try await FileService.updateFile(from: UpdateFileParams(request: request))

            // MARK: - KeyService Methods

            case .generateKey:
                jsonRpcResponse = try KeyService.generateKey(from: GenerateKeyParams(request: request))

            // MARK: - SDKClient Methods

            case .reset:
                jsonRpcResponse = try await SDKClient.client.reset(from: ResetParams(request: request))
            case .setOperator:
                jsonRpcResponse = try SDKClient.client.setOperator(from: SetOperatorParams(request: request))
            case .setup:
                jsonRpcResponse = try await SDKClient.client.setup(from: SetupParams(request: request))

            // MARK: - TokenService Methods

            case .airdropToken:
                jsonRpcResponse = try await TokenService.airdropToken(from: AirdropTokenParams(request: request))
            case .associateToken:
                jsonRpcResponse = try await TokenService.associateToken(from: AssociateTokenParams(request: request))
            case .burnToken:
                jsonRpcResponse = try await TokenService.burnToken(from: BurnTokenParams(request: request))
            case .cancelAirdrop:
                jsonRpcResponse = try await TokenService.cancelAirdrop(from: CancelAirdropParams(request: request))
            case .claimToken:
                jsonRpcResponse = try await TokenService.claimToken(from: ClaimTokenParams(request: request))
            case .createToken:
                jsonRpcResponse = try await TokenService.createToken(from: CreateTokenParams(request: request))
            case .deleteToken:
                jsonRpcResponse = try await TokenService.deleteToken(from: DeleteTokenParams(request: request))
            case .dissociateToken:
                jsonRpcResponse = try await TokenService.dissociateToken(from: DissociateTokenParams(request: request))
            case .freezeToken:
                jsonRpcResponse = try await TokenService.freezeToken(from: FreezeTokenParams(request: request))
            case .grantTokenKyc:
                jsonRpcResponse = try await TokenService.grantTokenKyc(from: GrantTokenKycParams(request: request))
            case .mintToken:
                jsonRpcResponse = try await TokenService.mintToken(from: MintTokenParams(request: request))
            case .pauseToken:
                jsonRpcResponse = try await TokenService.pauseToken(from: PauseTokenParams(request: request))
            case .rejectToken:
                jsonRpcResponse = try await TokenService.rejectToken(from: RejectTokenParams(request: request))
            case .revokeTokenKyc:
                jsonRpcResponse = try await TokenService.revokeTokenKyc(from: RevokeTokenKycParams(request: request))
            case .unfreezeToken:
                jsonRpcResponse = try await TokenService.unfreezeToken(from: UnfreezeTokenParams(request: request))
            case .unpauseToken:
                jsonRpcResponse = try await TokenService.unpauseToken(from: UnpauseTokenParams(request: request))
            case .updateTokenFeeSchedule:
                jsonRpcResponse = try await TokenService.updateTokenFeeSchedule(
                    from: UpdateTokenFeeScheduleParams(request: request))
            case .updateToken:
                jsonRpcResponse = try await TokenService.updateToken(from: UpdateTokenParams(request: request))
            case .wipeToken:
                jsonRpcResponse = try await TokenService.wipeToken(from: WipeTokenParams(request: request))

            // MARK: - TopicService Methods

            case .createTopic:
                jsonRpcResponse = try await TopicService.createTopic(from: CreateTopicParams(request: request))
            case .deleteTopic:
                jsonRpcResponse = try await TopicService.deleteTopic(from: DeleteTopicParams(request: request))
            case .submitTopicMessage:
                jsonRpcResponse = try await TopicService.submitTopicMessage(
                    from: SubmitTopicMessageParams(request: request))
            case .updateTopic:
                jsonRpcResponse = try await TopicService.updateTopic(from: UpdateTopicParams(request: request))

            // MARK: - Unsupported Method
            case .unsupported:
                throw JSONError.methodNotFound("\(request.method) not implemented.")
            }

            return JSONResponse(id: request.id, result: jsonRpcResponse)

        } catch let error as JSONError {
            print("JSONError: \(error)")
            return JSONResponse(id: request.id, error: error)

        } catch let error as HError {
            switch error.kind {
            case .transactionPreCheckStatus(let status, _),
                .queryPreCheckStatus(let status, _),
                .queryPaymentPreCheckStatus(let status, _),
                .receiptStatus(let status, _):
                print(error.description)
                return JSONResponse(
                    id: request.id,
                    error: JSONError.hieroError(
                        "Hiero error",
                        .dictionary([
                            "status": .string(Status.nameMap[status.rawValue]!),
                            "message": .string(error.description),
                        ])
                    )
                )
            case .queryNoPaymentPreCheckStatus(let status):
                print(error.description)
                return JSONResponse(
                    id: request.id,
                    error: JSONError.hieroError(
                        "Hiero error",
                        .dictionary([
                            "status": .string(Status.nameMap[status.rawValue]!),
                            "message": .string(error.description),
                        ])
                    )
                )
            default:
                print("HError (unhandled kind): \(error)")
                return JSONResponse(
                    id: request.id,
                    error: JSONError.internalError(
                        "Internal error",
                        .dictionary([
                            "data": .dictionary(["message": .string("\(error)")])
                        ])
                    )
                )
            }
        } catch let error {
            print("Unexpected error type: \(type(of: error)) - \(error)")
            // Fallback for unexpected errors.
            return JSONResponse(
                id: request.id,
                error: JSONError.internalError(
                    "Internal error",
                    .dictionary(["data": .dictionary(["message": .string("\(error)")])])
                )
            )
        }
    }

    // MARK: - Encoding

    /// Encodes a `JSONResponse` into an HTTP response with JSON content.
    private static func encodeJsonRpcResponseToHttpResponse(jsonResponse: JSONResponse) throws -> Response {
        do {
            let responseData = try JSONEncoder().encode(jsonResponse)
            if let errorCode = jsonResponse.error?.code {
                print("Returning error code: \(errorCode)")
            }
            return Response(status: .ok, headers: ["Content-Type": "application/json"], body: .init(data: responseData))
        } catch {
            print("Encoding failed: \(error)")
            throw error
        }
    }
}
