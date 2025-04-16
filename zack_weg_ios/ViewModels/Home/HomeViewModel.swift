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
    private var myPostsTask: Task<Void, Never>?
    private var nearbyPostsTask: Task<Void, Never>?
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    deinit {
        myPostsTask?.cancel()
        nearbyPostsTask?.cancel()
    }
    
    func fetchMyPosts() async {
        // Cancel any existing task
        myPostsTask?.cancel()
        
        myPostsTask = Task {
            isLoadingMyPosts = true
            defer { isLoadingMyPosts = false }
            
            do {
                let allPosts = try await apiService.getCurrentUserPosts()
                // Only update UI if task hasn't been canceled
                if !Task.isCancelled {
                    // Filter only active posts and limit to 5 for horizontal slider
                    myPosts = allPosts.filter { $0.status == "ACTIVE" }.prefix(5).map { $0 }
                }
            } catch {
                // Don't show cancellation errors in the UI
                if error is CancellationError {
                    print("My posts fetch was cancelled: \(error)")
                    return
                }
                
                // Check for NSURLErrorDomain cancellation errors
                if let nsError = error as NSError?, 
                   nsError.domain == NSURLErrorDomain,
                   nsError.code == NSURLErrorCancelled {
                    print("My posts fetch was cancelled with NSURLError: \(error)")
                    return
                }
                
                // Only log errors, don't display to user
                print("Error fetching my posts: \(error)")
            }
        }
    }
    
    func fetchNearbyPosts() async {
        // Cancel any existing task
        nearbyPostsTask?.cancel()
        
        nearbyPostsTask = Task {
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
                let posts = try await apiService.searchPosts(
                    postal_code: postalCode,
                    country_code: countryCode,
                    radius_km: 5.0,
                    limit: 5
                )
                
                // Only update UI if task hasn't been canceled
                if !Task.isCancelled {
                    nearbyPosts = posts
                }
            } catch {
                // Don't show cancellation errors in the UI
                if error is CancellationError {
                    print("Nearby posts fetch was cancelled: \(error)")
                    return
                }
                
                // Check for NSURLErrorDomain cancellation errors
                if let nsError = error as NSError?, 
                   nsError.domain == NSURLErrorDomain,
                   nsError.code == NSURLErrorCancelled {
                    print("Nearby posts fetch was cancelled with NSURLError: \(error)")
                    return
                }
                
                // Only log errors, don't display to user
                print("Error fetching nearby posts: \(error)")
            }
        }
    }
    
    func refreshAll() async {
        errorMessage = nil
        await fetchMyPosts()
        await fetchNearbyPosts()
    }
} 