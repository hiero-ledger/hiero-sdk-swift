// SPDX-License-Identifier: Apache-2.0

/// Convert a JSONObject to a typed value.
internal func getJson<T>(_ json: JSONObject, _ paramName: String, _ funcName: JSONRPCMethod) throws
    -> T
{
    if T.self == String.self {
        return try
            (json.stringValue
            ?? { throw JSONError.invalidParams("\(funcName.rawValue): \(paramName) MUST be a string.") }()) as! T
    }
    if T.self == Int32.self {
        return Int32(
            truncatingIfNeeded: try
                (json.intValue
                ?? { throw JSONError.invalidParams("\(funcName.rawValue): \(paramName) MUST be an int32.") }())) as! T
    }
    if T.self == UInt32.self {
        return UInt32(
            truncatingIfNeeded: try
                (json.intValue
                ?? { throw JSONError.invalidParams("\(funcName.rawValue): \(paramName) MUST be a uint32.") }())) as! T
    }
    if T.self == Int64.self {
        return try
            (json.intValue
            ?? { throw JSONError.invalidParams("\(funcName.rawValue): \(paramName) MUST be an int64.") }()) as! T
    }
    if T.self == UInt64.self {
        return UInt64(
            truncatingIfNeeded: try
                (json.intValue
                ?? { throw JSONError.invalidParams("\(funcName.rawValue): \(paramName) MUST be a uint64.") }())) as! T
    }
    if T.self == Double.self || T.self == Float.self {
        return try
            (json.doubleValue
            ?? { throw JSONError.invalidParams("\(funcName.rawValue): \(paramName) MUST be a double.") }()) as! T
    }
    if T.self == Bool.self {
        return try
            (json.boolValue
            ?? { throw JSONError.invalidParams("\(funcName.rawValue): \(paramName) MUST be a boolean.") }()) as! T
    }
    if T.self == [JSONObject].self {
        return try
            (json.listValue
            ?? { throw JSONError.invalidParams("\(funcName.rawValue): \(paramName) MUST be a list.") }()) as! T
    }
    if T.self == [String: JSONObject].self {
        return try
            (json.dictValue
            ?? { throw JSONError.invalidParams("\(funcName.rawValue): \(paramName) MUST be a dictionary.") }()) as! T
    }

    throw JSONError.invalidParams("\(funcName.rawValue): \(paramName) is NOT a valid type.")
}

/// Get a named value from a JSON parameters dictionary. If the parameter doesn't exist, return nil.
internal func getOptionalJsonParameter<T>(
    _ name: String, _ parameters: [String: JSONObject], _ funcName: JSONRPCMethod
) throws -> T? {
    return try parameters[name].flatMap { try getJson($0, name, funcName) as T }
}

/// Get a named value from a JSON parameters dictionary. If the parameter doesn't exist, throw.
internal func getRequiredJsonParameter<T>(
    _ name: String, _ parameters: [String: JSONObject], _ funcName: JSONRPCMethod
) throws -> T {
    return try getJson(
        parameters[name] ?? { throw JSONError.invalidParams("\(funcName): \(name) MUST be provided.") }(), name,
        funcName)
}

/// Get the parameters of the JSON-RPC request. If the parameters do not exist, throw.
internal func getRequiredParams(_ request: JSONRequest) throws -> [String: JSONObject] {
    return try getRequiredJsonParameter(
        "params", request.toDict(), JSONRPCMethod(rawValue: request.method) ?? JSONRPCMethod.undefinedMethod)
}

/// Get the parameters of the JSON-RPC request. If the parameters do not exist, return nil.
internal func getOptionalParams(_ request: JSONRequest) throws -> [String: JSONObject]? {
    return try getOptionalJsonParameter(
        "params", request.toDict(), JSONRPCMethod(rawValue: request.method) ?? JSONRPCMethod.undefinedMethod)
}
