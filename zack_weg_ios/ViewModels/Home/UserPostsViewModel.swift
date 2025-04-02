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
    @Published var selectedTab: PostStatus = .active
    
    // All posts fetched from API, used as source of truth
    private var allPosts: [Post] = []
    
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
    
    func fetchUserPosts(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            allPosts = try await apiService.getPostsByUser(userId: userId)
            filterPosts()
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
            self.allPosts = fetchedPosts
            filterPosts()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    var isCurrentUser: Bool {
        guard let userId = user?.id else { return false }
        return UserDefaults.standard.string(forKey: "userId") == userId
    }
    
    func setTab(_ tab: PostStatus) {
        selectedTab = tab
        filterPosts()
    }
    
    private func filterPosts() {
        // If not current user, show only active posts
        if !isCurrentUser {
            posts = allPosts.filter { $0.status == PostStatus.active.rawValue }
            return
        }
        
        // For current user, filter based on selected tab
        posts = allPosts.filter { $0.status == selectedTab.rawValue }
        
        // If no posts in current tab, check if we have any in other tabs
        if posts.isEmpty {
            let hasActivePosts = !allPosts.filter { $0.status == PostStatus.active.rawValue }.isEmpty
            let hasArchivedPosts = !allPosts.filter { $0.status == PostStatus.archived.rawValue }.isEmpty
            
            // If we have posts in another tab but none in current tab, 
            // switch to a tab that has posts (prefer active over archived)
            if hasActivePosts && selectedTab != .active {
                selectedTab = .active
                posts = allPosts.filter { $0.status == PostStatus.active.rawValue }
            } else if hasArchivedPosts && selectedTab != .archived {
                selectedTab = .archived
                posts = allPosts.filter { $0.status == PostStatus.archived.rawValue }
            }
        }
    }
} 