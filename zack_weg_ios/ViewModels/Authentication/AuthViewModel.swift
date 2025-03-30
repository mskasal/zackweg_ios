import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var error: String?
    @Published var isLoading = false
    @Published var authToken: String?
    @Published var selectedTab = 0
    @Published var currentUser: User?
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        // Try to restore user session
        if let token = KeychainManager.shared.getAuthToken() {
            self.authToken = token
            self.isAuthenticated = true
            Task {
                await fetchUserProfile()
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let token = try await apiService.signIn(email: email, password: password)
            KeychainManager.shared.saveAuthToken(token)
            UserDefaults.standard.set(email, forKey: "userEmail")
            
            // Get user profile to store user ID
            let user = try await apiService.getMyProfile()
            UserDefaults.standard.set(user.id, forKey: "userId")
            
            self.authToken = token
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    func signUp(email: String, password: String, postalCode: String, countryCode: String, nickName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let token = try await apiService.signUp(
                email: email,
                password: password,
                postalCode: postalCode,
                countryCode: countryCode,
                nickName: nickName
            )
            KeychainManager.shared.saveAuthToken(token)
            self.authToken = token
            self.isAuthenticated = true
            await fetchUserProfile()
        } catch {
            self.isAuthenticated = false
            self.authToken = nil
            self.currentUser = nil
            try? KeychainManager.shared.delete(key: KeychainManager.Keys.authToken)
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await apiService.resetPassword(email: email)
    }
    
    func signOut() {
        isAuthenticated = false
        authToken = nil
        currentUser = nil
        selectedTab = 0
        try? KeychainManager.shared.delete(key: KeychainManager.Keys.authToken)
    }
    
    private func fetchUserProfile() async {
        do {
            currentUser = try await apiService.getMyProfile()
        } catch {
            self.error = error.localizedDescription
            self.isAuthenticated = false
            self.authToken = nil
            self.currentUser = nil
            try? KeychainManager.shared.delete(key: KeychainManager.Keys.authToken)
        }
    }
} 