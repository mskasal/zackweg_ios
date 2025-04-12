import Foundation
import SwiftUI
import SwiftData

// Import models and services
@MainActor
class HomeViewModel: ObservableObject {
    @Published var myPosts: [Post] = []
    @Published var nearbyPosts: [Post] = []
    @Published var isLoadingMyPosts = false
    @Published var isLoadingNearbyPosts = false
    @Published var errorMessage: String?
    
    private let apiService: APIService
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    func fetchMyPosts() async {
        isLoadingMyPosts = true
        defer { isLoadingMyPosts = false }
        
        do {
            let allPosts = try await apiService.getCurrentUserPosts()
            // Filter only active posts and limit to 5 for horizontal slider
            myPosts = allPosts.filter { $0.status == "ACTIVE" }.prefix(5).map { $0 }
        } catch {
            errorMessage = "Failed to load your posts: \(error.localizedDescription)"
            print("Error fetching my posts: \(error)")
        }
    }
    
    func fetchNearbyPosts() async {
        isLoadingNearbyPosts = true
        defer { isLoadingNearbyPosts = false }
        
        do {
            // Get user's postal code
            let postalCode: String
            if let keychainPostalCode = KeychainManager.shared.getPostalCode(), !keychainPostalCode.isEmpty {
                postalCode = keychainPostalCode
            } else if let userDefaultsPostalCode = UserDefaults.standard.string(forKey: "postalCode"), !userDefaultsPostalCode.isEmpty {
                postalCode = userDefaultsPostalCode
            } else {
                postalCode = "10317" // Default fallback
                print("⚠️ Using default postal code for nearby search: 10317")
            }
            
            // Get user's country code
            let countryCode: String
            if let keychainCountryCode = KeychainManager.shared.getCountryCode(), !keychainCountryCode.isEmpty {
                countryCode = keychainCountryCode
            } else if let userDefaultsCountryCode = UserDefaults.standard.string(forKey: "countryCode"), !userDefaultsCountryCode.isEmpty {
                countryCode = userDefaultsCountryCode
            } else {
                countryCode = "DEU" // Default fallback
                print("⚠️ Using default country code for nearby search: DEU")
            }
            
            // Search for posts within 5km radius
            nearbyPosts = try await apiService.searchPosts(
                postal_code: postalCode,
                country_code: countryCode,
                radius_km: 5.0,
                limit: 5
            )
        } catch {
            errorMessage = "Failed to load nearby posts: \(error.localizedDescription)"
            print("Error fetching nearby posts: \(error)")
        }
    }
    
    func refreshAll() async {
        errorMessage = nil
        await fetchMyPosts()
        await fetchNearbyPosts()
    }
} 