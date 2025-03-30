import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingUpdateProfile = false
    @State private var showingUpdatePassword = false
    @State private var showingSignOutConfirmation = false
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        List {
            // Header section with user info
            Section {
                HStack(spacing: 16) {
                    // Avatar placeholder
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Text(getInitials())
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(UserDefaults.standard.string(forKey: "userNickName") ?? "User")
                            .font(.headline)
                        
                        Text(UserDefaults.standard.string(forKey: "userEmail") ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // Account settings
            Section(header: Text("settings.account".localized)) {
                Button(action: { showingUpdateProfile = true }) {
                    HStack {
                        Label("settings.update_profile".localized, systemImage: "person.circle")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { showingUpdatePassword = true }) {
                    HStack {
                        Label("settings.update_password".localized, systemImage: "lock")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // App settings (placeholder for future expansion)
            Section(header: Text("settings.app".localized)) {
                Toggle(isOn: .constant(true)) {
                    Label("settings.notifications".localized, systemImage: "bell")
                }
                
                Menu {
                    ForEach(LanguageManager.Language.allCases) { language in
                        Button(action: { 
                            languageManager.currentLanguage = language
                        }) {
                            HStack {
                                Text(language.displayName)
                                if languageManager.currentLanguage == language {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Label("settings.language".localized, systemImage: "globe")
                        Spacer()
                        Text(languageManager.currentLanguage.displayName)
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Support section
            Section(header: Text("settings.support".localized)) {
                Button(action: {
                    // Open help/support (placeholder)
                }) {
                    HStack {
                        Label("settings.help".localized, systemImage: "questionmark.circle")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    // Open terms/privacy (placeholder)
                }) {
                    HStack {
                        Label("settings.terms_privacy".localized, systemImage: "doc.text")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Sign out button
            Section {
                Button(action: {
                    showingSignOutConfirmation = true
                }) {
                    HStack {
                        Label("auth.sign_out".localized, systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer()
                    }
                }
                .foregroundColor(.red)
            }
            
            // App info section
            Section {
                HStack {
                    Text("settings.version".localized)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingUpdateProfile) {
            UpdateProfileView()
        }
        .sheet(isPresented: $showingUpdatePassword) {
            UpdatePasswordView()
        }
        .alert("auth.sign_out".localized, isPresented: $showingSignOutConfirmation) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("auth.sign_out".localized, role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("settings.sign_out_confirmation".localized)
        }
    }
    
    private func getInitials() -> String {
        let nickname = UserDefaults.standard.string(forKey: "userNickName") ?? "U"
        let components = nickname.components(separatedBy: " ")
        
        if components.count > 1, 
           let firstInitial = components[0].first,
           let lastInitial = components[1].first {
            return "\(firstInitial)\(lastInitial)"
        } else if let firstInitial = nickname.first {
            return String(firstInitial)
        }
        
        return "U"
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageManager.shared)
} 