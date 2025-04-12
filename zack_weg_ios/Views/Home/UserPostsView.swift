import SwiftUI

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct UserPostsView: View {
    @StateObject private var viewModel = UserPostsViewModel()
    @State private var errorMessage: ErrorMessage?
    @Environment(\.dismiss) private var dismiss
    let userId: String
    let userName: String?
    var disablePostNavigation: Bool = false
    
    init(userId: String, userName: String? = nil, disablePostNavigation: Bool = false) {
        self.userId = userId
        self.userName = userName
        self.disablePostNavigation = disablePostNavigation
        _viewModel = StateObject(wrappedValue: UserPostsViewModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector for the current user's posts
            if viewModel.isCurrentUser {
                statusTabSelector
            }
            
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView()
                    .padding()
            } else if viewModel.posts.isEmpty {
                emptyStateView
            } else {
                postsListView
            }
        }
        .navigationTitle(userName ?? "posts.user_posts".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.fetchUserProfile(userId: userId)
                await viewModel.fetchUserPosts(userId: userId)
            }
        }
        .onChange(of: viewModel.error) { error in
            if let errorStr = error {
                errorMessage = ErrorMessage(message: errorStr)
            }
        }
        .alert(item: $errorMessage) { error in
            Alert(
                title: Text("common.error".localized),
                message: Text(error.message),
                dismissButton: .default(Text("common.ok".localized))
            )
        }
    }
    
    // MARK: - View Components
    
    private var statusTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(UserPostsViewModel.PostStatus.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    private func tabButton(for status: UserPostsViewModel.PostStatus) -> some View {
        let isSelected = viewModel.selectedTab == status
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.setTab(status)
            }
        }) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: status.icon)
                        .font(.caption)
                    Text(status.displayName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
                .foregroundColor(isSelected ? status.color : .secondary)
                
                // Active indicator
                Rectangle()
                    .fill(isSelected ? status.color : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
            
            if viewModel.isCurrentUser {
                Text(
                    viewModel.selectedTab == .active
                    ? "posts.no_active_posts".localized 
                    : "posts.no_archived_posts".localized
                )
                .font(.headline)
                .foregroundColor(.gray)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("posts.create_post".localized)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 16)
            } else {
                Text("posts.no_posts_yet".localized)
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var postsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.posts) { post in
                    NavigationLink(destination: PostDetailView(postId: post.id, fromUserPostsView: true)) {
                        PostRowView(post: post)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .refreshable {
            await viewModel.refresh(userId: userId)
        }
    }
}

struct PostRowView: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            if !post.imageUrls.isEmpty, let url = URL(string: post.imageUrls[0]) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if post.offering == "SOLD_AT_PRICE" && post.price != nil {
                        Text("€\(String(format: "%.2f", post.price!))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    } else {
                        Text("common.free".localized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    if post.status == "ARCHIVED" {
                        Image(systemName: "archivebox.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(post.location.postalCode)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        UserPostsView(userId: "test-user-id", userName: "Test User")
    }
} 
