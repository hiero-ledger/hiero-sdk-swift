import Foundation
import SwiftDotenv

/// Handles loading environment variables from .env files.
/// This loads once per test process, regardless of how many test cases run.
public class DotenvLoader {
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
                    // Uses EnvironmentVariables.keys as the single source of truth
                    for key in EnvironmentVariables.keys {
                        setEnvironmentVariable(from: env, key: key)
                    }

                    EnvironmentVariables.printAllTestVariables()
                    return
                } catch {
                    // Failed to load .env, fall through to use environment variables directly
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
        EnvironmentVariables.printAllTestVariables()
    }

    private static func setEnvironmentVariable(from env: Environment, key: String) {
        if let value = env[key]?.stringValue {
            setenv(key, value, 1)
        }
    }
}
