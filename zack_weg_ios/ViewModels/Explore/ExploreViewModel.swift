import Foundation
import SwiftUI

@MainActor
class ExploreViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var error: String?
    @Published var isLoading = false
    @Published var searchResults: [Post] = []
    @Published var searchFilters = SearchFilters()
    @Published var lastViewedPostId: String? = nil
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        // Fetch user profile to get postal code
        Task {
            await fetchUserProfile()
        }
        
        // Restore the last viewed post ID
        self.lastViewedPostId = UserDefaults.standard.string(forKey: "ExploreLastViewedPostId")
    }
    
    // Store the last viewed post ID when it changes
    func setLastViewedPost(_ postId: String) {
        lastViewedPostId = postId
        UserDefaults.standard.set(postId, forKey: "ExploreLastViewedPostId")
    }
    
    // Check if a post ID exists in the current search results
    func containsPost(withId id: String) -> Bool {
        return searchResults.contains { $0.id == id }
    }
    
    // Add a method to count active filters
    func countActiveFilters() -> Int {
        var count = 0
        
        if !searchFilters.keyword.isEmpty { count += 1 }
        if !searchFilters.postalCode.isEmpty { count += 1 }
        if searchFilters.radiusKm != 20.0 { count += 1 }
        if !searchFilters.categoryId.isEmpty { count += 1 }
        if searchFilters.offering != nil { count += 1 }
        
        return count
    }
    
    private func fetchUserProfile() async {
        do {
            let user = try await apiService.getMyProfile()
            // Update search filters with user's postal code
            searchFilters.postalCode = user.location.postalCode
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func fetchPosts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            posts = try await apiService.getPosts()
            // Initially, show all posts in search results
            searchResults = posts
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // Add method to select a category
    func selectCategory(_ categoryId: String) {
        searchFilters.categoryId = categoryId
        Task {
            await searchPosts()
        }
    }
    
    func reportPost(_ postId: String, reason: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await apiService.reportPost(postId: postId, reason: reason)
    }
    
    func searchPosts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // If no filters are active, show all posts
            if searchFilters.keyword.isEmpty && 
               searchFilters.postalCode.isEmpty && 
               searchFilters.countryCode.isEmpty && 
               searchFilters.categoryId.isEmpty && 
               searchFilters.offering == nil {
                searchResults = posts
                return
            }
            
            // Otherwise, perform filtered search
            searchResults = try await apiService.searchPosts(
                keyword: searchFilters.keyword.isEmpty ? nil : searchFilters.keyword,
                postal_code: searchFilters.postalCode.isEmpty ? nil : searchFilters.postalCode,
                country_code: searchFilters.countryCode.isEmpty ? nil : searchFilters.countryCode,
                radius_km: searchFilters.radiusKm,
                category_id: searchFilters.categoryId.isEmpty ? nil : searchFilters.categoryId,
                offering: searchFilters.offering
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func startConversation(postId: String, message: String) async throws -> Conversation {
        return try await apiService.startConversation(postId: postId, message: message)
    }
    
    func sendMessage(conversationId: String, content: String) async throws -> Message {
        return try await apiService.sendMessage(conversationId: conversationId, content: content)
    }
} 
