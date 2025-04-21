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
    @State private var showingDeleteAccountAlert = false
    @State private var deleteConfirmationText = ""
    @State private var isDeletingAccount = false
    @State private var showingErrorAlert = false
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentTheme: ThemeManager.Theme = .system
    
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
            
            // App settings section
            Section(header: Text("settings.app".localized)) {
                // Notification preferences link
                NavigationLink(destination: NotificationPreferencesView()) {
                    Label("settings.notifications".localized, systemImage: "bell")
                }
                .accessibilityIdentifier("notificationsButton")
                
                // Theme selector
                Menu {
                    ForEach(ThemeManager.Theme.allCases) { theme in
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                themeManager.currentTheme = theme
                                currentTheme = theme
                            }
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
                
                // Language selector
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
            
            // Account Deletion section
            Section {
                Button(action: {
                    showingDeleteAccountAlert = true
                }) {
                    HStack {
                        Label("settings.delete_account".localized, systemImage: "trash")
                        Spacer()
                    }
                }
                .foregroundColor(.red)
                .accessibilityIdentifier("deleteAccountButton")
                
                Text("settings.delete_account_helper".localized)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .accessibilityIdentifier("deleteAccountHelperText")
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
        }
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
        .alert("settings.delete_account".localized, isPresented: $showingDeleteAccountAlert) {
            TextField("settings.delete_confirm_placeholder".localized, text: $deleteConfirmationText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            Button("common.cancel".localized, role: .cancel) {
                deleteConfirmationText = ""
            }
            Button("common.delete".localized, role: .destructive) {
                if deleteConfirmationText.lowercased() == "common.delete".localized.lowercased() {
                    // Call the delete account API
                    Task {
                        do {
                            isDeletingAccount = true
                            try await viewModel.deleteAccount()
                            isDeletingAccount = false
                            deleteConfirmationText = ""
                            
                            // Sign out after successful deletion
                            authViewModel.signOut()
                        } catch {
                            isDeletingAccount = false
                            showingErrorAlert = true
                            // Error is already handled in the viewModel
                        }
                    }
                }
            }
            .disabled(isDeletingAccount)
        } message: {
            Text("settings.delete_confirm_message".localized)
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("common.error".localized),
                message: Text(viewModel.error ?? "error.unknown".localized),
                dismissButton: .default(Text("common.ok".localized))
            )
        }
        .overlay {
            if isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.4)
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("settings.deleting_account".localized)
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            // Initialize current theme state from ThemeManager
            self.currentTheme = themeManager.currentTheme
        }
        // Only apply preferredColorScheme when not using system theme
        .modifier(ThemeModifier(theme: currentTheme))
        .onChange(of: themeManager.currentTheme) { newTheme in
            withAnimation(.easeInOut(duration: 0.3)) {
                self.currentTheme = newTheme
            }
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
        // Use German ('de') for Turkish language since Turkish pages don't exist
        let languageCode = languageManager.currentLanguage == .turkish ? "de" : languageManager.currentLanguage.rawValue
        if let url = URL(string: "https://www.zackweg.de/\(languageCode)/contact") {
            UIApplication.shared.open(url)
        }
    }
    
    // Open Terms of Service in browser
    private func openTermsURL() {
        // Use German ('de') for Turkish language since Turkish pages don't exist
        let languageCode = languageManager.currentLanguage == .turkish ? "de" : languageManager.currentLanguage.rawValue
        if let url = URL(string: "https://www.zackweg.de/\(languageCode)/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    // Open Privacy Policy in browser
    private func openPrivacyURL() {
        // Use German ('de') for Turkish language since Turkish pages don't exist
        let languageCode = languageManager.currentLanguage == .turkish ? "de" : languageManager.currentLanguage.rawValue
        if let url = URL(string: "https://www.zackweg.de/\(languageCode)/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    // Open About page in browser
    private func openAboutURL() {
        // Use German ('de') for Turkish language since Turkish pages don't exist
        let languageCode = languageManager.currentLanguage == .turkish ? "de" : languageManager.currentLanguage.rawValue
        if let url = URL(string: "https://www.zackweg.de/\(languageCode)/about") {
            UIApplication.shared.open(url)
        }
    }
    
    // Theme modifier to conditionally apply color scheme
    private struct ThemeModifier: ViewModifier {
        let theme: ThemeManager.Theme
        
        func body(content: Content) -> some View {
            if theme == .system {
                // Don't apply any specific color scheme, let system decide
                content
            } else {
                // Apply specific color scheme for light/dark modes
                content.preferredColorScheme(theme.colorScheme)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageManager.shared)
        .environmentObject(ThemeManager.shared)
} 
