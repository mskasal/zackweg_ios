import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var error: String?
    @Published var isSignedOut = false
    @Published var isLoading = false
    @Published var updateSuccess = false
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    enum SettingsError: LocalizedError {
        case networkError
        case authenticationError
        case serverError(String)
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .networkError:
                return "error.network.connection".localized
            case .authenticationError:
                return "error.auth.unauthorized".localized
            case .serverError(let message):
                return String(format: "error.server.with_message".localized, message)
            case .unknownError:
                return "error.unknown".localized
            }
        }
    }
    
    func signOut() {
        print("📱 Signing out user")
        // The APIService.signOut() is now called from AuthViewModel
        // Just set isSignedOut to true so the view can react
        isSignedOut = true
    }
    
    func updateProfile(email: String? = nil, postalCode: String? = nil, countryCode: String? = nil) async throws -> User {
        isLoading = true
        error = nil
        updateSuccess = false
        
        print("📱 Updating user profile with email: \(email ?? "unchanged"), postalCode: \(postalCode ?? "unchanged"), countryCode: \(countryCode ?? "unchanged")")
        
        do {
            let user = try await apiService.updateProfile(
                email: email,
                postalCode: postalCode,
                countryCode: countryCode
            )
            
            // Update UserDefaults with the new user information
            UserDefaults.standard.set(user.email, forKey: "userEmail")
            UserDefaults.standard.set(user.location.postalCode, forKey: "postalCode")
            UserDefaults.standard.set(user.location.countryCode, forKey: "countryCode")
            
            print("✓ Profile updated successfully")
            updateSuccess = true
            isLoading = false
            return user
        } catch let error as APIError {
            isLoading = false
            switch error {
            case .badRequest(let message):
                self.error = message ?? "error.input.invalid".localized
            case .unauthorized:
                self.error = "error.auth.session_expired".localized
            case .serverError(let code, let message):
                self.error = message ?? String(format: "error.server.with_code".localized, code)
            default:
                self.error = error.localizedDescription
            }
            print("❌ Profile update failed: \(error.localizedDescription)")
            throw error
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            print("❌ Profile update failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        isLoading = true
        error = nil
        updateSuccess = false
        
        print("📱 Updating user password")
        
        do {
            try await apiService.updatePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            print("✓ Password updated successfully")
            updateSuccess = true
            isLoading = false
        } catch let error as APIError {
            isLoading = false
            switch error {
            case .badRequest(let message):
                self.error = message ?? "error.input.invalid".localized
            case .unauthorized:
                self.error = "error.auth.session_expired".localized
            case .serverError(let code, let message):
                self.error = message ?? String(format: "error.server.with_code".localized, code)
            default:
                self.error = error.localizedDescription
            }
            print("❌ Password update failed: \(error.localizedDescription)")
            throw error
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            print("❌ Password update failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func handleError(_ error: NSError) {
        self.error = error.localizedDescription
        print("❌ Settings error: \(error.localizedDescription)")
        
        if error.domain == NSURLErrorDomain {
            self.error = SettingsError.networkError.errorDescription
        } else if error.code == 401 {
            self.error = SettingsError.authenticationError.errorDescription
        }
    }
    
    private func mapError(_ error: NSError) -> Error {
        if error.domain == NSURLErrorDomain {
            return SettingsError.networkError
        } else if error.code == 401 {
            return SettingsError.authenticationError
        } else if error.code >= 500 {
            return SettingsError.serverError("Server error \(error.code)")
        }
        return SettingsError.unknownError
    }
    
    func getMyProfile() async throws -> User {
        isLoading = true
        error = nil
        
        print("📱 Fetching user profile")
        
        do {
            let user = try await apiService.getMyProfile()
            
            // Store user data in UserDefaults
            UserDefaults.standard.set(user.email, forKey: "userEmail")
            UserDefaults.standard.set(user.location.postalCode, forKey: "postalCode")
            UserDefaults.standard.set(user.location.countryCode, forKey: "countryCode")
            
            print("✓ Profile fetched successfully")
            isLoading = false
            return user
        } catch let error as APIError {
            isLoading = false
            switch error {
            case .unauthorized:
                self.error = "error.auth.session_expired".localized
            case .serverError(let code, let message):
                self.error = message ?? String(format: "error.server.with_code".localized, code)
            default:
                self.error = error.localizedDescription
            }
            print("❌ Profile fetch failed: \(error.localizedDescription)")
            throw error
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            print("❌ Profile fetch failed: \(error.localizedDescription)")
            throw error
        }
    }
} 
