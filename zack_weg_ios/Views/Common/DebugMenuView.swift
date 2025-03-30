import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    
    // We'd normally reference AppConfiguration directly, but for now use directly
    // private var configValues = AppConfiguration.allConfigValues
    
    // Environment info from Info.plist or direct lookup
    private var environmentInfo: (name: String, baseURL: String, isDebug: Bool) {
        #if DEBUG
        return ("Development", "http://localhost:8080", true)
        #else
        return ("Production", "https://api.zackweg.com", false)
        #endif
    }
    
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
                    DebugInfoRow(label: "Environment", value: environmentInfo.name)
                    DebugInfoRow(label: "API Base URL", value: environmentInfo.baseURL)
                    DebugInfoRow(label: "Debug Mode", value: environmentInfo.isDebug ? "Enabled" : "Disabled")
                }
                
                Section(header: Text("User")) {
                    if let userId = UserDefaults.standard.string(forKey: "userId") {
                        DebugInfoRow(label: "User ID", value: userId)
                    } else {
                        DebugInfoRow(label: "User ID", value: "Not logged in")
                    }
                    
                    if let token = UserDefaults.standard.string(forKey: "authToken") {
                        DebugInfoRow(label: "Auth Token", value: String(token.prefix(20) + "..."))
                    } else {
                        DebugInfoRow(label: "Auth Token", value: "None")
                    }
                }
                
                Section {
                    Button(action: {
                        // Clear all UserDefaults (for testing)
                        let domain = Bundle.main.bundleIdentifier!
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                        UserDefaults.standard.synchronize()
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
