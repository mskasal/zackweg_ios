import Foundation
import SwiftUI

// Import models
@MainActor
class UserPostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var error: String?
    @Published var isLoading = false
    @Published var user: PublicUser?
    @Published var isRefreshing = false
    
    private let apiService: APIService
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    func fetchUserPosts(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            posts = try await apiService.getPostsByUser(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func fetchUserProfile(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            user = try await apiService.getUserProfile(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func refresh(userId: String) async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        // Fetch both user profile and posts concurrently
        async let userTask = apiService.getUserProfile(userId: userId)
        async let postsTask = apiService.getPostsByUser(userId: userId)
        
        do {
            let (fetchedUser, fetchedPosts) = try await (userTask, postsTask)
            self.user = fetchedUser
            self.posts = fetchedPosts
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    var isCurrentUser: Bool {
        guard let userId = user?.id else { return false }
        return UserDefaults.standard.string(forKey: "userId") == userId
    }
} 