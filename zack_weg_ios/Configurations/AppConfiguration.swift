import Foundation

/// App configuration that reads from Info.plist (which gets values from .xcconfig files)
enum AppConfiguration {
    // MARK: - API Configuration
    
    /// Base URL for API requests
    static var apiBaseURL: String {
        guard let baseURLProtocol = Bundle.main.object(forInfoDictionaryKey: "API_BASE_PROTOCOL") as? String else {
            fatalError("API_BASE_PROTOCOL not found in Info.plist")
        }
        guard let baseURLDomain = Bundle.main.object(forInfoDictionaryKey: "API_BASE_DOMAIN") as? String else {
            fatalError("API_BASE_DOMAIN not found in Info.plist")
        }
        return "\(baseURLProtocol)://\(baseURLDomain)"
    }
    
    /// API version
    static var apiVersion: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "API_VERSION") as? String else {
            fatalError("API_VERSION not found in Info.plist")
        }
        return version
    }
    
    // MARK: - Environment Information
    
    /// Name of the current environment (Development, Staging, Production)
    static var environmentName: String {
        guard let envName = Bundle.main.object(forInfoDictionaryKey: "ENV_NAME") as? String else {
            #if DEBUG
            return "Development"
            #else
            return "Production"
            #endif
        }
        return envName
    }
    
    /// Is this a development environment?
    static var isDevelopment: Bool {
        return environmentName == "Development"
    }
    
    /// Is this a staging environment?
    static var isStaging: Bool {
        return environmentName == "Staging"
    }
    
    /// Is this a production environment?
    static var isProduction: Bool {
        return environmentName == "Production"
    }
    
    /// Debug menu enabled flag
    static var isDebugMenuEnabled: Bool {
        guard let enableDebugMenuString = Bundle.main.object(forInfoDictionaryKey: "ENABLE_DEBUG_MENU") as? String else {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
        return enableDebugMenuString.lowercased() == "yes"
    }
    
    /// Log level for the application
    static var logLevel: LogLevel {
        guard let logLevelString = Bundle.main.object(forInfoDictionaryKey: "LOG_LEVEL") as? String else {
            #if DEBUG
            return .debug
            #else
            return .error
            #endif
        }
        
        switch logLevelString.uppercased() {
        case "DEBUG":
            return .debug
        case "INFO":
            return .info
        case "WARNING":
            return .warning
        case "ERROR":
            return .error
        default:
            #if DEBUG
            return .debug
            #else
            return .error
            #endif
        }
    }
    
    // MARK: - App Information
    
    /// App version (e.g., "1.0.0")
    static var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Build number (e.g., "42")
    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// App bundleId (e.g., "com.example.zackweg")
    static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "Unknown"
    }
    
    /// App name as shown to users
    static var appName: String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
               Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "ZackWeg"
    }
    
    // MARK: - All Configuration Values
    
    /// Dictionary of all configuration values for debugging
    static var allConfigValues: [String: String] {
        return [
            "App Name": appName,
            "Version": "\(version) (\(buildNumber))",
            "Bundle ID": bundleIdentifier,
            "Environment": environmentName,
            "API Base URL": apiBaseURL,
            "API Version": apiVersion,
            "Log Level": logLevel.rawValue,
            "Debug Menu Enabled": isDebugMenuEnabled ? "Yes" : "No"
        ]
    }
}

// MARK: - LogLevel
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
} 
