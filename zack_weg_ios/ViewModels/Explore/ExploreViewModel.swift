import Foundation
import SwiftUI

@MainActor
class ExploreViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var categories: [Category] = []
    @Published var error: String?
    @Published var isLoading = false
    @Published var isCategoriesLoading = false  // Add specific loading state for categories
    @Published var searchResults: [Post] = []
    @Published var searchFilters = SearchFilters()
    
    // Add new properties for hierarchical categories
    @Published var topLevelCategories: [Category] = []
    @Published var subCategories: [String: [Category]] = [:] // Parent ID to list of child categories
    @Published var selectedParentCategory: Category? = nil
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        // Fetch user profile to get postal code
        Task {
            await fetchUserProfile()
        }
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
    
    func fetchCategories() async {
        isCategoriesLoading = true
        
        do {
            categories = try await apiService.getCategories()
            
            // Organize categories hierarchically
            topLevelCategories = categories.filter { $0.isTopLevel }
            
            // Group subcategories by parent ID
            subCategories = Dictionary(grouping: categories.filter { !$0.isTopLevel }, 
                                     by: { $0.parentId! })
            
            // If we previously had a selectedParentCategory, try to find it in the new data
            if let selectedId = selectedParentCategory?.id {
                selectedParentCategory = categories.first { $0.id == selectedId }
            }
            
        } catch {
            self.error = "Failed to load categories: \(error.localizedDescription)"
            print("Error fetching categories: \(error)")
        }
        
        isCategoriesLoading = false
    }
    
    // Add method to select a parent category
    func selectParentCategory(_ category: Category?) {
        selectedParentCategory = category
        // If nil, clear the category filter
        if category == nil {
            searchFilters.categoryId = ""
            Task {
                await searchPosts()
            }
        } else if !category!.hasChildren(in: categories) {
            // If category has no children, set it as the filter directly
            searchFilters.categoryId = category!.id
            Task {
                await searchPosts()
            }
        }
    }
    
    // Add method to select a subcategory
    func selectSubcategory(_ category: Category) {
        searchFilters.categoryId = category.id
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
