import SwiftUI

struct PublicUserPostsView: View {
    @StateObject private var viewModel = UserPostsViewModel()
    @State private var errorMessage: ErrorMessage?
    
    let userId: String
    let userName: String?
    
    var body: some View {
        ZStack {
            // Loading state
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView()
                    .padding()
            }
            
            // Empty state
            else if viewModel.posts.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("posts.no_posts_yet".localized)
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Posts list
            else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(destination: PostDetailView(post: post, fromUserPostsView: true)) {
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
                errorMessage = ErrorMessage(message: errorStr, detail: viewModel.errorDetail)
            }
        }
        .alert(item: $errorMessage) { error in
            Alert(
                title: Text("common.error".localized),
                message: Text(error.detail != nil ? "\(error.message)\n\n\(error.detail!)" : error.message),
                dismissButton: .default(Text("common.ok".localized))
            )
        }
    }
}

#Preview {
    NavigationView {
        PublicUserPostsView(userId: "test-user-id", userName: "Test User")
    }
} 