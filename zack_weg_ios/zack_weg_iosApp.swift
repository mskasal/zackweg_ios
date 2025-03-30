//
//  zack_weg_iosApp.swift
//  zack_weg_ios
//
//  Created by Mustafa Samed Kasal on 25.03.25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

@main
struct zack_weg_iosApp: App {
    @StateObject private var navigationState = NavigationState()
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    init() {
        // Configure services
        setupServices()
        
        // Configure the app to use the stored language
        LanguageManager.shared.configureAppLanguage()
    }
    
    private func setupServices() {
        // Print configuration information in debug builds
        let config = ConfigurationManager.shared
        
        // Verify environment configuration
        let configWorking = config.verifyEnvironmentConfiguration()
        if !configWorking {
            print("⚠️ WARNING: Environment configuration is not working correctly!")
            print("   - Check that your xcconfig files are properly set up")
            print("   - Verify Info.plist contains the xcconfig variables")
            print("   - Ensure the correct scheme and configuration are selected")
        }
        
        // Start network monitoring
        ErrorHandlingService.shared.startNetworkMonitoring()
        
        // Setup observers for auth events
        setupAuthObservers()
        
        // Migrate UserDefaults to KeychainManager if needed
        migrateUserDefaultsToKeychain()
    }
    
    private func setupAuthObservers() {
        // Listen for session expiration
        NotificationCenter.default.addObserver(
            forName: Notification.Name("UserSessionExpired"),
            object: nil,
            queue: .main
        ) { _ in
            // Handle session expiration - could show an alert or redirect to login
            print("⚠️ User session expired, redirecting to login")
        }
    }
    
    private func migrateUserDefaultsToKeychain() {
        // Check if we need to migrate from UserDefaults to Keychain
        if let authToken = UserDefaults.standard.string(forKey: "authToken"), 
           !KeychainManager.shared.hasValue(for: KeychainManager.Keys.authToken) {
            KeychainManager.shared.saveAuthToken(authToken)
        }
        
        if let userId = UserDefaults.standard.string(forKey: "userId"),
           !KeychainManager.shared.hasValue(for: KeychainManager.Keys.userId) {
            KeychainManager.shared.saveUserId(userId)
        }
        
        if let email = UserDefaults.standard.string(forKey: "userEmail"),
           !KeychainManager.shared.hasValue(for: KeychainManager.Keys.userEmail) {
            KeychainManager.shared.saveUserEmail(email)
        }
        
        if let postalCode = UserDefaults.standard.string(forKey: "postalCode"),
           !KeychainManager.shared.hasValue(for: KeychainManager.Keys.postalCode) {
            KeychainManager.shared.savePostalCode(postalCode)
        }
        
        if let countryCode = UserDefaults.standard.string(forKey: "countryCode"),
           !KeychainManager.shared.hasValue(for: KeychainManager.Keys.countryCode) {
            KeychainManager.shared.saveCountryCode(countryCode)
        }
        
        if let nickName = UserDefaults.standard.string(forKey: "userNickName"),
           !KeychainManager.shared.hasValue(for: KeychainManager.Keys.nickName) {
            KeychainManager.shared.saveNickName(nickName)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationState)
                .environmentObject(languageManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    // Clean up services when app terminates
                    ErrorHandlingService.shared.stopNetworkMonitoring()
                }
        }
    }
}
