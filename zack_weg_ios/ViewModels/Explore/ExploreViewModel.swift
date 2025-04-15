import Foundation
import SwiftUI

@MainActor
class ExploreViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var error: String?
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var searchResults: [Post] = []
    @Published var searchFilters = SearchFilters()
    @Published var hasMoreResults = true
    
    // Pagination properties
    private var currentOffset = 0
    private let pageSize = 10
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        // Fetch user profile to get postal code
        Task {
            await fetchUserProfile()
        }
    }
    
    private func fetchUserProfile() async {
        do {
            let user = try await apiService.getMyProfile()
            // Update search filters with user's postal code
            searchFilters.postalCode = user.location.postalCode
        } catch let apiError as APIError {
            switch apiError {
            case .unauthorized:
                // User not logged in, just continue without setting postal code
                print("User not authenticated. Using default location.")
            case .serverError(let code, let message):
                self.error = message ?? String(format: "error.server.with_code".localized, code)
            default:
                self.error = apiError.localizedDescription
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // Add method to select a category
    func selectCategory(_ categoryId: String) {
        // If the category is already selected, remove it
        if searchFilters.categoryIds.contains(categoryId) {
            searchFilters.categoryIds.removeAll { $0 == categoryId }
        } else {
            // Otherwise add it
            searchFilters.categoryIds.append(categoryId)
        }
        
        // We no longer trigger searchPosts automatically here
        // Task {
        //     await searchPosts(resetOffset: true)
        // }
    }
    
    func reportPost(_ postId: String, reason: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await apiService.reportPost(postId: postId, reason: reason)
        } catch let apiError as APIError {
            switch apiError {
            case .notFound:
                throw NSError(domain: "AppError", code: 404, userInfo: [NSLocalizedDescriptionKey: "messages.post_not_available".localized])
            case .unauthorized:
                throw NSError(domain: "AppError", code: 401, userInfo: [NSLocalizedDescriptionKey: "error.auth.unauthorized".localized])
            case .badRequest(let message):
                throw NSError(domain: "AppError", code: 400, userInfo: [NSLocalizedDescriptionKey: message ?? "error.input.invalid".localized])
            case .serverError(let code, let message):
                throw NSError(domain: "AppError", code: code, userInfo: [NSLocalizedDescriptionKey: message ?? String(format: "error.server.with_code".localized, code)])
            default:
                throw apiError
            }
        }
    }
    
    // Modified to support pagination
    func searchPosts(resetOffset: Bool = true) async {
        if resetOffset {
            isLoading = true
            currentOffset = 0
            hasMoreResults = true
        } else {
            isLoadingMore = true
        }
        
        defer { 
            isLoading = false
            isLoadingMore = false
        }
        
        do {
            // If no filters are active and it's the initial load, show all posts
            if searchFilters.keyword.isEmpty && 
               searchFilters.postalCode.isEmpty && 
               searchFilters.countryCode.isEmpty && 
               searchFilters.categoryIds.isEmpty && 
               resetOffset {
                searchResults = posts
                return
            }
            
            // Otherwise, perform filtered search with pagination
            let newResults = try await apiService.searchPosts(
                keyword: searchFilters.keyword.isEmpty ? nil : searchFilters.keyword,
                postal_code: searchFilters.postalCode.isEmpty ? nil : searchFilters.postalCode,
                country_code: searchFilters.countryCode.isEmpty ? nil : searchFilters.countryCode,
                radius_km: searchFilters.radiusKm,
                limit: pageSize,
                offset: currentOffset,
                category_ids: searchFilters.categoryIds.isEmpty ? nil : searchFilters.categoryIds
            )
            
            // Update hasMoreResults based on the number of results returned
            hasMoreResults = newResults.count >= pageSize
            
            // If resetting, replace results, otherwise append
            if resetOffset {
                searchResults = newResults
            } else {
                // Filter out any posts that already exist in searchResults
                let duplicates = newResults.filter { newPost in
                    searchResults.contains { existingPost in
                        existingPost.id == newPost.id
                    }
                }
                
                // Log information about duplicates if any are found
                if !duplicates.isEmpty {
                    print("⚠️ Found \(duplicates.count) duplicate posts while loading more!")
                    for duplicate in duplicates {
                        print("🔄 Duplicate post ID: \(duplicate.id), title: \(duplicate.title)")
                    }
                    print("💡 Working around ForEach duplicate ID issue by filtering them out")
                }
                
                // Filter out duplicates before appending
                let uniqueNewResults = newResults.filter { newPost in
                    !searchResults.contains { existingPost in
                        existingPost.id == newPost.id
                    }
                }
                
                print("📊 Pagination stats: Loaded \(newResults.count) posts, \(duplicates.count) duplicates, adding \(uniqueNewResults.count) unique posts")
                searchResults.append(contentsOf: uniqueNewResults)
                
                // Update the offset with the actual number of unique results to maintain pagination correctly
                currentOffset += uniqueNewResults.count
                return
            }
            
            // Update the offset for the next page
            currentOffset += newResults.count
        } catch let apiError as APIError {
            switch apiError {
            case .badRequest(let message):
                self.error = message ?? "error.input.invalid".localized
            case .serverError(let code, let message):
                self.error = message ?? String(format: "error.server.with_code".localized, code)
            default:
                self.error = apiError.localizedDescription
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // New method to load more posts when scrolling
    func loadMoreIfNeeded(currentItem: Post) async {
        // Check if we're near the end of the list and not already loading more
        let thresholdIndex = searchResults.index(searchResults.endIndex, offsetBy: -3)
        if searchResults.firstIndex(where: { $0.id == currentItem.id }) ?? 0 >= thresholdIndex,
           !isLoadingMore && hasMoreResults {
            // Load the next page
            await searchPosts(resetOffset: false)
        }
    }
    
    func startConversation(postId: String, message: String) async throws -> Conversation {
        return try await apiService.startConversation(postId: postId, message: message)
    }
    
    func sendMessage(conversationId: String, content: String) async throws -> Message {
        return try await apiService.sendMessage(conversationId: conversationId, content: content)
    }
    
    // Add a method to count active filters
    func countActiveFilters() -> Int {
        var count = 0
        
        if !searchFilters.keyword.isEmpty { count += 1 }
        if !searchFilters.postalCode.isEmpty { count += 1 }
        if searchFilters.radiusKm != 20.0 { count += 1 }
        if !searchFilters.categoryIds.isEmpty { count += 1 }
        
        return count
    }
} 
