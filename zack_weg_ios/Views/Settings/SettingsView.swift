//
//  SettingsView.swift
//  zack_weg_ios
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingUpdateProfile = false
    @State private var showingUpdatePassword = false
    @State private var showingSignOutConfirmation = false
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        List {
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
                .accessibilityIdentifier("updateProfileButton")
                
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
                .accessibilityIdentifier("updatePasswordButton")
            }
            
            // App settings (placeholder for future expansion)
            Section(header: Text("settings.app".localized)) {
                // Toggle(isOn: .constant(true)) {
                //     Label("settings.notifications".localized, systemImage: "bell")
                // }
                
                Menu {
                    ForEach(ThemeManager.Theme.allCases) { theme in
                        Button(action: { 
                            themeManager.currentTheme = theme
                        }) {
                            HStack {
                                Text(theme.displayName)
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .accessibilityIdentifier("themeOption_\(theme.rawValue)")
                    }
                } label: {
                    HStack {
                        Label("settings.theme".localized, systemImage: "circle.lefthalf.filled")
                        Spacer()
                        Text(themeManager.currentTheme.displayName)
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .accessibilityIdentifier("themeSelector")
                
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
                        .accessibilityIdentifier("languageOption_\(language.rawValue)")
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
                .accessibilityIdentifier("languageSelector")
            }
            
            // Support section
            Section(header: Text("settings.support".localized)) {
                Button(action: {
                    openHelpSupportURL()
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
                .accessibilityIdentifier("helpSupportButton")
                
                Button(action: {
                    openTermsURL()
                }) {
                    HStack {
                        Label("settings.terms".localized, systemImage: "doc.text")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .accessibilityIdentifier("termsButton")
                
                Button(action: {
                    openPrivacyURL()
                }) {
                    HStack {
                        Label("settings.privacy".localized, systemImage: "hand.raised")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .accessibilityIdentifier("privacyButton")
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
                .accessibilityIdentifier("signOutButton")
            }
            
            // App info section
            Section {
                HStack {
                    Text("settings.version".localized)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("appVersionValue")
                }
                .accessibilityIdentifier("appVersionRow")
                
                Button(action: {
                    openAboutURL()
                }) {
                    HStack {
                        Text("© 2025 ZackWeg. All rights reserved.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .accessibilityIdentifier("copyrightButton")
            }
        }
        .accessibilityIdentifier("settingsScreenList")
        .navigationTitle("settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingUpdateProfile) {
            NavigationView {
                UpdateProfileView()
            }
        }
        .sheet(isPresented: $showingUpdatePassword) {
            NavigationView {
                UpdatePasswordView()
            }
        }
        .alert(isPresented: $showingSignOutConfirmation) {
            signOutAlert()
        }
    }
    
    private func signOutAlert() -> Alert {
        Alert(
            title: Text("auth.sign_out".localized),
            primaryButton: .destructive(Text("auth.sign_out".localized)) {
                authViewModel.signOut()
            },
            secondaryButton: .cancel(Text("common.cancel".localized))
        )
    }
    
    // Open Help & Support in browser
    private func openHelpSupportURL() {
        if let url = URL(string: "https://www.zackweg.com/\(languageManager.currentLanguage.rawValue)/contact") {
            UIApplication.shared.open(url)
        }
    }
    
    // Open Terms of Service in browser
    private func openTermsURL() {
        if let url = URL(string: "https://www.zackweg.com/\(languageManager.currentLanguage.rawValue)/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    // Open Privacy Policy in browser
    private func openPrivacyURL() {
        if let url = URL(string: "https://www.zackweg.com/\(languageManager.currentLanguage.rawValue)/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    // Open About page in browser
    private func openAboutURL() {
        if let url = URL(string: "https://www.zackweg.com/\(languageManager.currentLanguage.rawValue)/about") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageManager.shared)
        .environmentObject(ThemeManager.shared)
} 