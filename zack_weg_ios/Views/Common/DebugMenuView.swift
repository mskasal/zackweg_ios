import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Use ConfigurationManager for environment info
    private let configManager = ConfigurationManager.shared
    
    // App information from Bundle
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "ZackWeg"
    }
    
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private var bundleId: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("App Information")) {
                    DebugInfoRow(label: "App Name", value: appName)
                    DebugInfoRow(label: "Version", value: "\(version) (\(buildNumber))")
                    DebugInfoRow(label: "Bundle ID", value: bundleId)
                }
                
                Section(header: Text("Environment")) {
                    DebugInfoRow(label: "Environment", value: configManager.environmentName)
                    DebugInfoRow(label: "API Base URL", value: configManager.apiBaseURL)
                    DebugInfoRow(label: "API Version", value: configManager.apiVersion)
                    DebugInfoRow(label: "Full API URL", value: configManager.apiBaseURLWithVersion)
                    DebugInfoRow(label: "Log Level", value: configManager.logLevel)
                    DebugInfoRow(label: "Debug Menu Enabled", value: configManager.isDebugMenuEnabled ? "Yes" : "No")
                    DebugInfoRow(label: "Environment Type", value: getEnvironmentType())
                }
                
                Section(header: Text("User")) {
                    if let userId = KeychainManager.shared.getUserId() {
                        DebugInfoRow(label: "User ID", value: userId)
                    } else {
                        DebugInfoRow(label: "User ID", value: "Not logged in")
                    }
                    
                    if let token = KeychainManager.shared.getAuthToken() {
                        DebugInfoRow(label: "Auth Token", value: String(token.prefix(20) + "..."))
                    } else {
                        DebugInfoRow(label: "Auth Token", value: "None")
                    }
                    
                    if let email = KeychainManager.shared.getUserEmail() {
                        DebugInfoRow(label: "Email", value: email)
                    }
                    
                    if let postalCode = KeychainManager.shared.getPostalCode() {
                        DebugInfoRow(label: "Postal Code", value: postalCode)
                    }
                }
                
                Section {
                    Button("Run Configuration Diagnostics") {
                        configManager.runDiagnostics()
                    }
                    .foregroundColor(.blue)
                    
                    Button(action: {
                        // Clear all UserDefaults (for testing)
                        let domain = Bundle.main.bundleIdentifier!
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                        UserDefaults.standard.synchronize()
                        
                        // Clear keychain items
                        KeychainManager.shared.clearAll()
                    }) {
                        Text("Clear User Data")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Debug Menu")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            #endif
        }
    }
    
    // Helper to determine environment type in readable format
    private func getEnvironmentType() -> String {
        if configManager.isDevelopment {
            return "Development"
        } else if configManager.isStaging {
            return "Staging"
        } else if configManager.isProduction {
            return "Production"
        } else {
            return "Unknown"
        }
    }
}

struct DebugInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    DebugMenuView()
} 
