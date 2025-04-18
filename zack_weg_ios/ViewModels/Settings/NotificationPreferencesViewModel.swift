import Foundation
import SwiftUI

@MainActor
class NotificationPreferencesViewModel: ObservableObject {
    @Published var notificationPreferences: [NotificationPreference] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    /// Fetch notification preferences from the API
    func fetchNotificationPreferences() async {
        isLoading = true
        error = nil
        
        do {
            let preferences = try await apiService.getNotificationPreferences()
            notificationPreferences = preferences.notificationPreferences
            print("✓ Notification preferences fetched successfully")
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
            print("❌ Failed to fetch notification preferences: \(error.localizedDescription)")
        }
    }
    
    /// Update a specific notification preference
    /// - Parameters:
    ///   - type: The notification type
    ///   - channel: The notification channel
    ///   - enabled: Whether notifications should be enabled
    func updatePreference(type: NotificationType, channel: NotificationChannel, enabled: Bool) async {
        // Find and update the preference in the local array
        if let index = notificationPreferences.firstIndex(where: { $0.type == type && $0.channel == channel }) {
            // Create a copy of the array to update
            var updatedPreferences = notificationPreferences
            
            // Create a new preference with the updated value
            let updatedPreference = NotificationPreference(type: type, channel: channel, enabled: enabled)
            
            // Replace the old preference with the updated one
            updatedPreferences[index] = updatedPreference
            
            // Save the changes
            await savePreferences(updatedPreferences)
        }
    }
    
    /// Save all notification preferences to the API
    /// - Parameter preferences: The preferences to save
    func savePreferences(_ preferences: [NotificationPreference]) async {
        isLoading = true
        error = nil
        
        let preferencesWrapper = NotificationPreferences(notificationPreferences: preferences)
        
        do {
            let updatedPreferences = try await apiService.updateNotificationPreferences(preferencesWrapper)
            notificationPreferences = updatedPreferences.notificationPreferences
            print("✓ Notification preferences updated successfully")
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
            print("❌ Failed to update notification preferences: \(error.localizedDescription)")
        }
    }
    
    /// Helper method to handle errors
    /// - Parameter error: The error to handle
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .badRequest(let message):
                self.error = message ?? "error.input.invalid".localized
            case .unauthorized:
                self.error = "error.auth.session_expired".localized
            case .serverError(let code, let message):
                self.error = message ?? String(format: "error.server.with_code".localized, code)
            default:
                self.error = error.localizedDescription
            }
        } else {
            self.error = error.localizedDescription
        }
    }
} 