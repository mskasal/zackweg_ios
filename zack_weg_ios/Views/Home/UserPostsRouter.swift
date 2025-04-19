import SwiftUI

/// Router view that decides whether to show CurrentUserPostsView or PublicUserPostsView
struct UserPostsRouter: View {
    let userId: String
    let userName: String?
    var forceRefresh: Bool = false
    
    var body: some View {
        // Check if this is the current user
        if userId == UserDefaults.standard.string(forKey: "userId") || 
           userId == KeychainManager.shared.getUserId() {
            // Show current user view
            CurrentUserPostsView(forceRefresh: forceRefresh)
        } else {
            // Show other user view
            PublicUserPostsView(userId: userId, userName: userName)
        }
    }
}

#Preview {
    NavigationView {
        // Preview with current user
        UserPostsRouter(userId: UserDefaults.standard.string(forKey: "userId") ?? "preview-id", userName: "user")
    }
} 
