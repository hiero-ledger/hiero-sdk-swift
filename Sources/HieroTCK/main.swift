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
        app.post { req -> Response in
            var jsonRpcRequest: JSONRequest

            // Decode request body into JSON-RPC object, or return error response if invalid.
            do {
                jsonRpcRequest = try req.content.decode(JSONRequest.self)
            } catch let error as JSONError {
                return try encodeJsonRpcResponseToHttpResponse(jsonResponse: JSONResponse(id: nil, error: error))
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
                jsonRpcResponse = try await AccountService.service.approveAllowance(
                    from: ApproveAllowanceParams(request: request))
            case .createAccount:
                jsonRpcResponse = try await AccountService.service.createAccount(
                    from: CreateAccountParams(request: request))
            case .deleteAccount:
                jsonRpcResponse = try await AccountService.service.deleteAccount(
                    from: DeleteAccountParams(request: request))
            case .deleteAllowance:
                jsonRpcResponse = try await AccountService.service.deleteAllowance(
                    from: DeleteAllowanceParams(request: request))
            case .transferCrypto:
                jsonRpcResponse = try await AccountService.service.transferCrypto(
                    from: TransferCryptoParams(request: request))
            case .updateAccount:
                jsonRpcResponse = try await AccountService.service.updateAccount(
                    from: UpdateAccountParams(request: request))

            // MARK: - KeyService Methods

            case .generateKey:
                jsonRpcResponse = try KeyService.service.generateKey(from: GenerateKeyParams(request: request))

            // MARK: - SDKClient Methods

            case .reset:
                jsonRpcResponse = try SDKClient.client.reset(from: ResetParams(request: request))
            case .setup:
                jsonRpcResponse = try SDKClient.client.setup(from: SetupParams(request: request))

            // MARK: - TokenService Methods

            case .associateToken:
                jsonRpcResponse = try await TokenService.service.associateToken(
                    from: AssociateTokenParams(request: request))
            case .burnToken:
                jsonRpcResponse = try await TokenService.service.burnToken(from: BurnTokenParams(request: request))
            case .createToken:
                jsonRpcResponse = try await TokenService.service.createToken(from: CreateTokenParams(request: request))
            case .deleteToken:
                jsonRpcResponse = try await TokenService.service.deleteToken(from: DeleteTokenParams(request: request))
            case .dissociateToken:
                jsonRpcResponse = try await TokenService.service.dissociateToken(
                    from: DissociateTokenParams(request: request))
            case .freezeToken:
                jsonRpcResponse = try await TokenService.service.freezeToken(from: FreezeTokenParams(request: request))
            case .grantTokenKyc:
                jsonRpcResponse = try await TokenService.service.grantTokenKyc(
                    from: GrantTokenKycParams(request: request))
            case .mintToken:
                jsonRpcResponse = try await TokenService.service.mintToken(from: MintTokenParams(request: request))
            case .pauseToken:
                jsonRpcResponse = try await TokenService.service.pauseToken(from: PauseTokenParams(request: request))
            case .revokeTokenKyc:
                jsonRpcResponse = try await TokenService.service.revokeTokenKyc(
                    from: RevokeTokenKycParams(request: request))
            case .unfreezeToken:
                jsonRpcResponse = try await TokenService.service.unfreezeToken(
                    from: UnfreezeTokenParams(request: request))
            case .unpauseToken:
                jsonRpcResponse = try await TokenService.service.unpauseToken(
                    from: UnpauseTokenParams(request: request))
            case .updateTokenFeeSchedule:
                jsonRpcResponse =
                    try await TokenService.service.updateTokenFeeSchedule(
                        from: UpdateTokenFeeScheduleParams(request: request))
            case .updateToken:
                jsonRpcResponse = try await TokenService.service.updateToken(from: UpdateTokenParams(request: request))

            // MARK: - Unsupported Method
            case .unsupported:
                throw JSONError.methodNotFound("\(request.method) not implemented.")
            }

            return JSONResponse(id: request.id, result: jsonRpcResponse)

        } catch let error as JSONError {
            return JSONResponse(id: request.id, error: error)

        } catch let error as HError {
            switch error.kind {
            case .transactionPreCheckStatus(let status, _),
                .queryPreCheckStatus(let status, _),
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
            default:
                print(error)
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
        let responseData = try JSONEncoder().encode(jsonResponse)
        return Response(status: .ok, headers: ["Content-Type": "application/json"], body: .init(data: responseData))
    }
}
