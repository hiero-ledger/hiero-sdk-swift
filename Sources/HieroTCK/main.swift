/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */
import Vapor

@testable import Hiero

let server = TCKServer()
try TCKServer.main()

internal class TCKServer {

    ////////////////
    /// INTERNAL ///
    ////////////////

    internal static func main() throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = Application(env)
        defer { app.shutdown() }

        app.http.server.configuration.port = 80
        app.post { req -> Response in
            var jsonRpcRequest: JSONRequest
            do {
                jsonRpcRequest = try req.content.decode(JSONRequest.self)
            } catch let error as JSONError {
                return try encodeJsonRpcResponseToHttpResponse(jsonResponse: JSONResponse(id: nil, error: error))
            }

            let response = await server.processRequest(request: jsonRpcRequest)
            return try encodeJsonRpcResponseToHttpResponse(jsonResponse: response)
        }

        try app.run()
    }

    ///////////////
    /// PRIVATE ///
    ///////////////

    /// Fully process a JSON-RPC request and generate a response.
    private func processRequest(request: JSONRequest) async -> JSONResponse {
        do {
            let jsonRpcResponse: JSONObject
            let method = JSONRPCMethod(rawValue: request.method) ?? JSONRPCMethod.undefinedMethod

            switch method {
            ///
            /// AccountService JSON-RPC methods.
            ///
            case JSONRPCMethod.createAccount:
                jsonRpcResponse = try await AccountService.service.createAccount(CreateAccountParams(request))
            case JSONRPCMethod.deleteAccount:
                jsonRpcResponse = try await AccountService.service.deleteAccount(DeleteAccountParams(request))
            case JSONRPCMethod.updateAccount:
                jsonRpcResponse = try await AccountService.service.updateAccount(UpdateAccountParams(request))
            ///
            /// KeyService JSON-RPC methods.
            ///
            case JSONRPCMethod.generateKey:
                jsonRpcResponse = try KeyService.service.generateKey(GenerateKeyParams(request))
            ///
            /// SdkClient JSON-RPC methods.
            ///
            case JSONRPCMethod.reset:
                jsonRpcResponse = try SDKClient.client.reset(ResetParams(request))
            case JSONRPCMethod.setup:
                jsonRpcResponse = try SDKClient.client.setup(SetupParams(request))
            ///
            /// TokenService JSON-RPC methods.
            ///
            case JSONRPCMethod.associateToken:
                jsonRpcResponse = try await TokenService.service.associateToken(AssociateTokenParams(request))
            case JSONRPCMethod.burnToken:
                jsonRpcResponse = try await TokenService.service.burnToken(BurnTokenParams(request))
            case JSONRPCMethod.createToken:
                jsonRpcResponse = try await TokenService.service.createToken(CreateTokenParams(request))
            case JSONRPCMethod.deleteToken:
                jsonRpcResponse = try await TokenService.service.deleteToken(DeleteTokenParams(request))
            case JSONRPCMethod.dissociateToken:
                jsonRpcResponse = try await TokenService.service.dissociateToken(DissociateTokenParams(request))
            case JSONRPCMethod.freezeToken:
                jsonRpcResponse = try await TokenService.service.freezeToken(FreezeTokenParams(request))
            case JSONRPCMethod.grantTokenKyc:
                jsonRpcResponse = try await TokenService.service.grantTokenKyc(GrantTokenKycParams(request))
            case JSONRPCMethod.mintToken:
                jsonRpcResponse = try await TokenService.service.mintToken(MintTokenParams(request))
            case JSONRPCMethod.pauseToken:
                jsonRpcResponse = try await TokenService.service.pauseToken(PauseTokenParams(request))
            case JSONRPCMethod.revokeTokenKyc:
                jsonRpcResponse = try await TokenService.service.revokeTokenKyc(RevokeTokenKycParams(request))
            case JSONRPCMethod.unfreezeToken:
                jsonRpcResponse = try await TokenService.service.unfreezeToken(UnfreezeTokenParams(request))
            case JSONRPCMethod.unpauseToken:
                jsonRpcResponse = try await TokenService.service.unpauseToken(UnpauseTokenParams(request))
            case JSONRPCMethod.updateTokenFeeSchedule:
                jsonRpcResponse =
                    try await TokenService.service.updateTokenFeeSchedule(UpdateTokenFeeScheduleParams(request))
            case JSONRPCMethod.updateToken:
                jsonRpcResponse = try await TokenService.service.updateToken(UpdateTokenParams(request))
            ///
            /// Undefined method or method not provided.
            ///
            case JSONRPCMethod.undefinedMethod:
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
                return JSONResponse(
                    id: request.id,
                    error: JSONError.hieroError(
                        "Hiero error",
                        JSONObject.dictionary([
                            "status": JSONObject.string(Status.nameMap[status.rawValue]!),
                            "message": JSONObject.string(error.description),
                        ])
                    )
                )
            default:
                return JSONResponse(
                    id: request.id,
                    error: JSONError.internalError(
                        "Internal error",
                        JSONObject.dictionary([
                            "data": JSONObject.dictionary(["message": JSONObject.string("\(error)")])
                        ])
                    )
                )
            }
        } catch let error {
            return JSONResponse(
                id: request.id,
                error: JSONError.internalError(
                    "Internal error",
                    JSONObject.dictionary(["data": JSONObject.dictionary(["message": JSONObject.string("\(error)")])])
                )
            )
        }
    }

    /// Fills an HTTP response with a JSON-RPC response.
    private static func encodeJsonRpcResponseToHttpResponse(jsonResponse: JSONResponse) throws -> Response {
        let responseData = try JSONEncoder().encode(jsonResponse)
        return Response(status: .ok, headers: ["Content-Type": "application/json"], body: .init(data: responseData))
    }
}
