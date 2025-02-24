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
import Foundation
import Hiero
import Vapor

private let jsonRpcVersion = "2.0"

internal struct JSONRequest: Decodable {
    internal let jsonrpc: String
    internal var id: Int
    internal var method: String
    internal var params: JSONObject?

    private enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case method
        case params
    }

    internal init(id: Int, method: String, params: JSONObject) {
        self.jsonrpc = jsonRpcVersion
        self.id = id
        self.method = method
        self.params = params
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let jsonrpc = try container.decodeIfPresent(String.self, forKey: .jsonrpc) else {
            throw JSONError.invalidRequest("jsonrpc field MUST be set to \"2.0\"")
        }
        self.jsonrpc = jsonrpc

        if let idInt = try container.decodeIfPresent(Int.self, forKey: .id) {
            self.id = idInt
        } else if let idStr = try container.decodeIfPresent(String.self, forKey: .id), let idInt = Int(idStr) {
            self.id = idInt
        } else {
            throw JSONError.invalidRequest("id field MUST exist and be a number or string.")
        }

        guard let method = try container.decodeIfPresent(String.self, forKey: .method) else {
            throw JSONError.invalidRequest("method field MUST exist and be a string")
        }
        self.method = method

        if let params = try container.decodeIfPresent(JSONObject.self, forKey: .params) {
            self.params = params
        } else if container.contains(.params) {
            throw JSONError.invalidRequest("params field MUST be an array, object or null")
        } else {
            self.params = nil
        }
    }

    internal func toDict() -> [String: JSONObject] {
        var dict = [
            "jsonrpc": JSONObject.string(jsonRpcVersion),
            "id": JSONObject.int(Int64(self.id)),
            "method": JSONObject.string(self.method),
        ]

        if let params = self.params {
            dict["params"] = params
        }

        return dict
    }
}

internal struct JSONResponse: Encodable {
    internal let jsonrpc: String
    internal var id: Int?
    internal var result: JSONObject?
    internal var error: JSONError?

    internal init(id: Int, result: JSONObject) {
        self.jsonrpc = jsonRpcVersion
        self.id = id
        self.result = result
        self.error = nil
    }

    internal init(id: Int?, error: JSONError) {
        self.jsonrpc = jsonRpcVersion
        self.id = id
        self.result = nil
        self.error = error
    }
}

internal enum JSONError: Encodable, Error {
    case hieroError(String, JSONObject? = nil)
    case invalidRequest(String, JSONObject? = nil)
    case methodNotFound(String, JSONObject? = nil)
    case invalidParams(String, JSONObject? = nil)
    case internalError(String, JSONObject? = nil)
    case parseError(String, JSONObject? = nil)

    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }

    internal var code: Int {
        switch self {
        case .hieroError: return -32001
        case .invalidRequest: return -32600
        case .methodNotFound: return -32601
        case .invalidParams: return -32602
        case .internalError: return -32603
        case .parseError: return -32700
        }
    }

    internal var message: String {
        switch self {
        case .hieroError(let message, _),
            .invalidRequest(let message, _),
            .methodNotFound(let message, _),
            .invalidParams(let message, _),
            .internalError(let message, _),
            .parseError(let message, _):
            return message
        }
    }

    internal var data: JSONObject? {
        switch self {
        case .hieroError(_, let data),
            .invalidRequest(_, let data),
            .methodNotFound(_, let data),
            .invalidParams(_, let data),
            .internalError(_, let data),
            .parseError(_, let data):
            return data
        }
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(data, forKey: .data)
    }
}

internal enum JSONObject: Codable {
    case string(String)
    case int(Int64)
    case double(Double)
    case bool(Bool)
    case list([JSONObject])
    case dictionary([String: JSONObject])

    internal var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }
    internal var intValue: Int64? {
        if case .int(let value) = self {
            return value
        }
        return nil
    }
    internal var doubleValue: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }
    internal var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }
    internal var listValue: [JSONObject]? {
        if case .list(let value) = self {
            return value
        }
        return nil
    }
    internal var dictValue: [String: JSONObject]? {
        if case .dictionary(let value) = self {
            return value
        }
        return nil
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([JSONObject].self) {
            self = .list(value)
        } else if let value = try? container.decode([String: JSONObject].self) {
            self = .dictionary(value)
        } else {
            throw JSONError.invalidParams("param type not recognized")
        }
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .list(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
}
