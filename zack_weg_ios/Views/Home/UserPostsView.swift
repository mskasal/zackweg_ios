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
    
    init(userId: String, userName: String? = nil) {
        self.userId = userId
        self.userName = userName
        _viewModel = StateObject(wrappedValue: UserPostsViewModel())
    }
    
    var body: some View {
        VStack {
            
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView()
                    .padding()
            } else if viewModel.posts.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("posts.no_posts_yet".localized)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    if viewModel.isCurrentUser {
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
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    let gridSpacing: CGFloat = 12
                    let columns = [
                        GridItem(.adaptive(minimum: 160, maximum: 180), spacing: gridSpacing)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: gridSpacing) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(destination: PostDetailView(postId: post.id)) {
                                PostGridItemView(post: post)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, gridSpacing)
                    .padding(.vertical)
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
}

struct PostGridItemView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Image container with fixed size
            ZStack {
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
                } else {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(height: 160) // Fixed height
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .clipped() // Ensure content doesn't overflow
            
            // Title and price in a fixed-height container
            VStack(alignment: .leading, spacing: 2) {
                Text(post.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                if post.offering == "SOLD_AT_PRICE" && post.price != nil {
                    Text("€\(String(format: "%.2f", post.price!))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("common.free".localized)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .frame(height: 40) // Fixed height for text area
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        UserPostsView(userId: "test-user-id", userName: "Test User")
    }
} 
