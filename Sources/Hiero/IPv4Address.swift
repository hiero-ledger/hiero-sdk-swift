// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Cross-platform IPv4 address implementation
///
/// This provides a simple, consistent IPv4 address type that works
/// identically on all platforms (macOS, iOS, Linux, etc.).
public struct IPv4Address: Equatable, Hashable, CustomStringConvertible {
    /// Raw 4-byte representation of the IPv4 address
    public let rawValue: Data
    
    /// Initialize from raw bytes (must be exactly 4 bytes)
    public init?(_ data: Data) {
        guard data.count == 4 else {
            return nil
        }
        self.rawValue = data
    }
    
    /// Initialize from string representation (e.g., "192.168.1.1")
    public init?(_ string: String) {
        let components = string.split(separator: ".")
        guard components.count == 4 else {
            return nil
        }
        
        var bytes = Data()
        bytes.reserveCapacity(4)
        
        for component in components {
            guard let byte = UInt8(component), byte <= 255 else {
                return nil
            }
            bytes.append(byte)
        }
        
        guard bytes.count == 4 else {
            return nil
        }
        
        self.rawValue = bytes
    }
    
    /// String representation (e.g., "192.168.1.1")
    public var description: String {
        guard rawValue.count == 4 else {
            return "0.0.0.0"
        }
        return rawValue.map { String($0) }.joined(separator: ".")
    }
    
    /// Debug description
    public var debugDescription: String {
        description
    }
}

