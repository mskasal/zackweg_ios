import Foundation
import SwiftUI

/// ConfigurationManager provides access to environment-specific configuration
/// values defined in .xcconfig files and exposed through Info.plist
class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    // MARK: - API Configuration
    
    /// Base URL for the API
    var apiBaseURL: String {
        return getValue(for: "API_BASE_URL") ?? "https://api.zackweg.com"
    }
    
    /// API version
    var apiVersion: String {
        return getValue(for: "API_VERSION") ?? "v1"
    }
    
    /// Complete API base URL with version
    var apiBaseURLWithVersion: String {
        return "\(apiBaseURL)/\(apiVersion)"
    }
    
    // MARK: - Environment Configuration
    
    /// Name of the current environment (Development, Staging, Production)
    var environmentName: String {
        return getValue(for: "ENV_NAME") ?? "Production"
    }
    
    /// Log level for the current environment
    var logLevel: String {
        return getValue(for: "LOG_LEVEL") ?? "ERROR"
    }
    
    /// Whether to enable the debug menu
    var isDebugMenuEnabled: Bool {
        return (getValue(for: "ENABLE_DEBUG_MENU") ?? "NO") == "YES"
    }
    
    /// Whether the app is running in a development environment
    var isDevelopment: Bool {
        return environmentName == "Development"
    }
    
    /// Whether the app is running in a staging environment
    var isStaging: Bool {
        return environmentName == "Staging"
    }
    
    /// Whether the app is running in a production environment
    var isProduction: Bool {
        return environmentName == "Production"
    }
    
    // MARK: - Private Methods
    
    /// Gets a value for the given key from Info.plist or environment variables
    private func getValue(for key: String) -> String? {
        // Try to get directly from Info.plist
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty {
            // Check if the value is a variable reference like $(SOME_VAR)
            if value.hasPrefix("$(") && value.hasSuffix(")") {
                // This is a variable reference that wasn't expanded
                print("⚠️ Found unexpanded variable: \(value) for key: \(key)")
                
                // Extract the variable name
                let varName = String(value.dropFirst(2).dropLast(1))
                
                // Try to get the value from environment
                if let envValue = ProcessInfo.processInfo.environment[varName] {
                    return envValue
                }
            } else {
                return value
            }
        }
        
        // Finally, try environment variables directly
        return ProcessInfo.processInfo.environment[key]
    }
    
    // MARK: - Debug Helpers
    
    /// Check if the environment configuration is working properly
    func verifyEnvironmentConfiguration() -> Bool {
        let apiURLExists = apiBaseURL != "https://api.zackweg.com" // Check if not using fallback
        let envNameExists = getValue(for: "ENV_NAME") != nil
        
        let isWorking = apiURLExists && envNameExists
        
        print("🔍 Environment Configuration Check:")
        print("  - API URL found: \(apiURLExists ? "✅" : "❌") - \(apiBaseURL)")
        print("  - ENV_NAME found: \(envNameExists ? "✅" : "❌") - \(environmentName)")
        print("  - Overall status: \(isWorking ? "✅ WORKING" : "❌ NOT WORKING")")
        
        // Examine bundle 
        print("📦 Bundle Path: \(Bundle.main.bundlePath)")
        
        // Check if xcconfig files being loaded
        print("🔧 Build Configuration: \(Bundle.main.object(forInfoDictionaryKey: "DTXcodeBuild") ?? "Unknown")")
        print("🔧 PRODUCT_BUNDLE_IDENTIFIER: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        
        // Check resources
        print("🖼️ Asset Catalog Resources:")
        if let assetURLs = Bundle.main.urls(forResourcesWithExtension: "car", subdirectory: nil) {
            for url in assetURLs {
                print("  - \(url.lastPathComponent)")
            }
        } else {
            print("  ❌ No asset catalogs found")
        }
        
        // Check localizations
        print("🌍 Available Localizations: \(Bundle.main.localizations)")
        
        if !isWorking {
            // Try to find the actual plist files
            print("🔍 Searching for plist files in app bundle:")
            let fileManager = FileManager.default
            if let bundleURL = Bundle.main.bundleURL as NSURL? {
                do {
                    let contents = try fileManager.contentsOfDirectory(at: bundleURL as URL, includingPropertiesForKeys: nil, options: [])
                    for item in contents where item.pathExtension == "plist" {
                        print("  - \(item.lastPathComponent)")
                    }
                } catch {
                    print("  ❌ Error listing bundle contents: \(error)")
                }
            }
            
            // Attempt to read process info environment variables
            print("🌎 Environment Variables:")
            let processInfo = ProcessInfo.processInfo
            let environment = processInfo.environment
            for (key, value) in environment where key.contains("API") || key.contains("ENV") || key.contains("BUNDLE") || key.contains("INFOPLIST") {
                print("  - \(key): \(value)")
            }
            
            // Print Xcode build settings
            print("📝 Build Settings from Environment:")
            for (key, value) in environment {
                if key.starts(with: "XC") || key.starts(with: "BUILD") || key.starts(with: "CONFIGURATION") {
                    print("  - \(key): \(value)")
                }
            }
        }
        
        return isWorking
    }
    
    /// Run comprehensive diagnostics to troubleshoot build and configuration issues
    func runDiagnostics() {
        print("📊 COMPREHENSIVE DIAGNOSTICS 📊")
        print("===============================")
        
        // 1. Check bundle resources
        print("\n📦 BUNDLE RESOURCES:")
        print("Bundle path: \(Bundle.main.bundlePath)")
        
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        print("Listing top-level bundle contents:")
        do {
            let contents = try fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
            for item in contents {
                print("  - \(item.lastPathComponent)")
            }
        } catch {
            print("Error listing bundle contents: \(error)")
        }
        
        // 2. Check asset catalogs
        print("\n🖼️ ASSET CATALOGS:")
        if let assetURLs = Bundle.main.urls(forResourcesWithExtension: "car", subdirectory: nil) {
            print("Found \(assetURLs.count) asset catalog(s):")
            for url in assetURLs {
                print("  - \(url.lastPathComponent)")
            }
        } else {
            print("❌ No asset catalogs found in bundle")
        }
        
        // 3. Check localizations
        print("\n🌍 LOCALIZATIONS:")
        let localizations = Bundle.main.localizations
        print("Available localizations: \(localizations)")
        
        // Test loading a string
        let testKey = "explore.title"
        let localizedString = NSLocalizedString(testKey, comment: "")
        if localizedString != testKey {
            print("✅ Successfully loaded localized string for key: \(testKey)")
        } else {
            print("❌ Failed to load localized string for key: \(testKey)")
        }
        
        // 4. Check xcconfig variable loading
        print("\n⚙️ XCCONFIG VARIABLES:")
        let varsToCheck = ["API_BASE_URL", "API_VERSION", "ENV_NAME", "LOG_LEVEL", "ENABLE_DEBUG_MENU"]
        for varName in varsToCheck {
            let value = Bundle.main.object(forInfoDictionaryKey: varName) as? String
            let valueDisplay = value ?? "❌ NOT FOUND"
            print("\(varName): \(valueDisplay)")
            
            // Check if it's an unexpanded variable
            if let val = value, val.hasPrefix("$(") && val.hasSuffix(")") {
                print("  ⚠️ Variable not expanded: \(val)")
            }
        }
        
        // 5. Check build configuration
        print("\n🔧 BUILD CONFIGURATION:")
        if let infoDictionary = Bundle.main.infoDictionary {
            print("CFBundleIdentifier: \(infoDictionary["CFBundleIdentifier"] ?? "Unknown")")
            print("CFBundleName: \(infoDictionary["CFBundleName"] ?? "Unknown")")
            print("CFBundleDisplayName: \(infoDictionary["CFBundleDisplayName"] ?? "Unknown")")
            
            // Look for configuration-specific keys
            for (key, value) in infoDictionary {
                if key.contains("DT") || key.contains("SDK") || key.contains("BUILD") {
                    print("\(key): \(value)")
                }
            }
        }
        
        print("\n===============================")
        print("📊 END DIAGNOSTICS 📊")
    }
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG
        printConfiguration()
        // Run comprehensive diagnostics on startup in debug builds
        runDiagnostics()
        #endif
    }
    
    // Print the current configuration for debugging purposes
    private func printConfiguration() {
        print("📱 App Configuration:")
        print("  Environment: \(environmentName)")
        print("  API Base URL: \(apiBaseURL)")
        print("  API Version: \(apiVersion)")
        print("  Log Level: \(logLevel)")
        print("  Debug Menu Enabled: \(isDebugMenuEnabled ? "YES" : "NO")")
        
        // Check if we're using fallback values (indicates configuration problem)
        if apiBaseURL == "https://api.zackweg.com" {
            print("⚠️ WARNING: Using fallback API URL. Check xcconfig configuration.")
            
            // Print entire bundle dictionary for debugging
            print("📝 Dumping Bundle.main.infoDictionary for debugging:")
            if let info = Bundle.main.infoDictionary {
                for (key, value) in info {
                    print("  \(key): \(value)")
                }
            }
        }
    }
} 
