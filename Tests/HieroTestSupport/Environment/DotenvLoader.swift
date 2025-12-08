import Foundation
import SwiftDotenv

/// Handles loading environment variables from .env files.
/// This loads once per test process, regardless of how many test cases run.
public class DotenvLoader {
    /// All Hiero test environment variables
    private static let environmentVariableKeys = [
        "HIERO_OPERATOR_ID",
        "HIERO_OPERATOR_KEY",
        "HIERO_PROFILE",
        "HIERO_NETWORK_NAME",
        "HIERO_CONSENSUS_NODES",
        "HIERO_CONSENSUS_NODE_ACCOUNT_IDS",
        "HIERO_MIRROR_NODES",
        "HIERO_VERBOSE",
        "HIERO_MAX_DURATION",
        "HIERO_PARALLEL",
        "HIERO_ENABLE_CLEANUP",
        "HIERO_CLEANUP_ACCOUNTS",
        "HIERO_CLEANUP_TOKENS",
        "HIERO_CLEANUP_FILES",
        "HIERO_CLEANUP_TOPICS",
        "HIERO_CLEANUP_CONTRACTS",
    ]

    /// Ensures .env is loaded exactly once per process
    private static let loaded: Void = {
        loadDotenvFile()
    }()

    /// Call this to ensure .env has been loaded
    public static func ensureLoaded() {
        _ = loaded
    }

    private static func loadDotenvFile() {
        let fileManager = FileManager.default
        var currentPath = fileManager.currentDirectoryPath

        for _ in 0..<5 {
            let envPath = (currentPath as NSString).appendingPathComponent(".env")

            if fileManager.fileExists(atPath: envPath) {
                do {
                    let env = try Dotenv.load(path: envPath)

                    // Set all environment variables from .env
                    // This is necessary because ProcessInfo.processInfo.environment is read-only
                    for key in environmentVariableKeys {
                        setEnvironmentVariable(from: env, key: key)
                    }

                    // Print loaded variables if verbose logging is enabled
                    if EnvironmentVariables.verboseLogging {
                        print("Loaded environment variables from \(envPath):")
                        for key in environmentVariableKeys {
                            if let value = env[key]?.stringValue {
                                // Redact sensitive values
                                let displayValue = key.contains("KEY") ? "***" : value
                                print("  \(key) = \(displayValue)")
                            }
                        }
                    }

                    return
                } catch {
                    print("Failed to load .env from \(envPath): \(error)")
                    return
                }
            }

            let parentPath = (currentPath as NSString).deletingLastPathComponent
            if parentPath == currentPath {
                break
            }
            currentPath = parentPath
        }

        print("No .env file found, using environment variables directly")
    }

    private static func setEnvironmentVariable(from env: Environment, key: String) {
        if let value = env[key]?.stringValue {
            setenv(key, value, 1)
        }
    }
}
