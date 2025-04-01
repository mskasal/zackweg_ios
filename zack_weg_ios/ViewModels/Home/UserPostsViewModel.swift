import Foundation
import SwiftUI

// Import models
@MainActor
class UserPostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var error: String?
    @Published var isLoading = false
    @Published var user: PublicUser?
    
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
} 