import Foundation
import SwiftUI

// Import models
@MainActor
class UserPostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var error: String?
    @Published var errorDetail: String?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var selectedTab: PostStatus = .active
    
    // Different types of user data
    @Published var currentUser: User?      // Full user data (only for current user)
    @Published var publicUser: PublicUser? // Public user data (for other users)
    @Published var postUser: PostUser?     // Basic user data from posts
    
    // All posts fetched from API, used as source of truth
    private var allPosts: [Post] = []
    
    // Cached filtered posts for better performance
    private var activePosts: [Post] = []
    private var archivedPosts: [Post] = []
    
    enum PostStatus: String, CaseIterable, Identifiable {
        case active = "ACTIVE"
        case archived = "ARCHIVED"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .active:
                return "posts.status_active".localized
            case .archived:
                return "posts.status_archived".localized
            }
        }
        
        var icon: String {
            switch self {
            case .active:
                return "checkmark.circle.fill"
            case .archived:
                return "archivebox.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .active:
                return .green
            case .archived:
                return .orange
            }
        }
    }
    
    private let apiService: APIService
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    func fetchUserPosts(userId: String?) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // If userId is nil or matches current user, fetch current user's posts
            if userId == nil || userId == UserDefaults.standard.string(forKey: "userId") {
                allPosts = try await apiService.getCurrentUserPosts()
                if !allPosts.isEmpty {
                    // Store basic user info from posts
                    postUser = allPosts[0].user
                    // Clear other user types since this is current user
                    publicUser = nil
                }
            } else {
                // Fetch other user's posts
                allPosts = try await apiService.getPostsByUser(userId: userId!)
                if !allPosts.isEmpty {
                    // Store basic user info from posts
                    postUser = allPosts[0].user
                    // Clear current user since this is another user
                    currentUser = nil
                }
            }
            
            // Prefetch images for posts
            prefetchImagesForPosts(allPosts)
            
            // Cache filtered posts
            updateFilteredPostsCache()
            
            // Set posts based on selected tab
            filterPosts()
            
        } catch {
            self.error = error.localizedDescription
            // Extract detailed error info if available
            if let appError = error as? AppError {
                self.errorDetail = appError.detailedErrorInfo
            } else if let apiError = error as? APIError, case .serverError(let code, let message) = apiError {
                print("❌ Server error \(code): \(message ?? "Unknown error")")
                self.error = message ?? "error.server".localized
                
                // Create a custom AppError to get the detailed error info
                if let message = message {
                    self.errorDetail = AppError.custom(message).detailedErrorInfo
                }
            } else {
                self.errorDetail = nil
            }
        }
    }
    
    func fetchUserProfile(userId: String?) async {
        // Only fetch if we don't have any user info yet
        guard postUser == nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if userId == nil || userId == UserDefaults.standard.string(forKey: "userId") {
                currentUser = try await apiService.getMyProfile()
            } else {
                publicUser = try await apiService.getUserProfile(userId: userId!)
            }
        } catch {
            self.error = error.localizedDescription
            // Extract detailed error info if available
            if let appError = error as? AppError {
                self.errorDetail = appError.detailedErrorInfo
            } else if let apiError = error as? APIError, case .serverError(let code, let message) = apiError {
                print("❌ Server error \(code): \(message ?? "Unknown error")")
                self.error = message ?? "error.server".localized
                
                // Create a custom AppError to get the detailed error info
                if let message = message {
                    self.errorDetail = AppError.custom(message).detailedErrorInfo
                }
            } else {
                self.errorDetail = nil
            }
        }
    }
    
    func refresh(userId: String?) async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        // Determine if we're fetching current user or other user
        let isCurrentUser = userId == nil || userId == UserDefaults.standard.string(forKey: "userId")
        
        do {
            // Just fetch posts since they contain user information
            allPosts = try await (isCurrentUser ? 
                apiService.getCurrentUserPosts() : 
                apiService.getPostsByUser(userId: userId!))
            
            if !allPosts.isEmpty {
                postUser = allPosts[0].user
                // Clear appropriate user type based on who we're viewing
                if isCurrentUser {
                    publicUser = nil
                } else {
                    currentUser = nil
                }
            }
            
            // Prefetch images for posts
            prefetchImagesForPosts(allPosts)
            
            // Cache filtered posts
            updateFilteredPostsCache()
            
            // Update displayed posts
            filterPosts()
        } catch {
            self.error = error.localizedDescription
            // Extract detailed error info if available
            if let appError = error as? AppError {
                self.errorDetail = appError.detailedErrorInfo
            } else if let apiError = error as? APIError, case .serverError(let code, let message) = apiError {
                print("❌ Server error \(code): \(message ?? "Unknown error")")
                self.error = message ?? "error.server".localized
                
                // Create a custom AppError to get the detailed error info
                if let message = message {
                    self.errorDetail = AppError.custom(message).detailedErrorInfo
                }
            } else {
                self.errorDetail = nil
            }
        }
    }
    
    var isCurrentUser: Bool {
        guard let postUserId = postUser?.id else { return false }
        return UserDefaults.standard.string(forKey: "userId") == postUserId
    }
    
    // Helper to check if there are any archived posts
    var hasArchivedPosts: Bool {
        return !allPosts.filter { $0.status == PostStatus.archived.rawValue }.isEmpty
    }
    
    // Helper to get the display name, prioritizing the most detailed user info available
    var displayName: String {
        if let name = currentUser?.nickName {
            return name
        }
        if let name = publicUser?.nickName {
            return name
        }
        return postUser?.nickName ?? "Unknown"
    }
    
    func setTab(_ tab: PostStatus) {
        selectedTab = tab
        filterPosts()
    }
    
    // Prefetch post images
    private func prefetchImagesForPosts(_ posts: [Post]) {
        for post in posts {
            if !post.imageUrls.isEmpty {
                // Start loading the first image of each post
                ImagePrefetcher.shared.prefetchImage(post.imageUrls[0])
            }
        }
    }
    
    // Update the cached filtered posts
    private func updateFilteredPostsCache() {
        activePosts = allPosts.filter { $0.status == PostStatus.active.rawValue }
        archivedPosts = allPosts.filter { $0.status == PostStatus.archived.rawValue }
    }
    
    private func filterPosts() {
        // If not current user, show only active posts
        if !isCurrentUser {
            posts = activePosts
            return
        }
        
        // For current user, use the cached posts based on selected tab
        switch selectedTab {
        case .active:
            posts = activePosts
        case .archived:
            posts = archivedPosts
        }
    }
}

// Image prefetching helper
class ImagePrefetcher {
    static let shared = ImagePrefetcher()
    
    private init() {}
    
    func prefetchImage(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // Use URLSession to start loading the image data
        URLSession.shared.dataTask(with: url) { _, _, _ in
            // We don't need to do anything with the data, just loading it into the cache
        }.resume()
    }
} 