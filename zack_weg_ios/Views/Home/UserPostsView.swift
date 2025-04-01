import SwiftUI

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct UserPostsView: View {
    @StateObject private var viewModel = UserPostsViewModel()
    @State private var errorMessage: ErrorMessage?
    let userId: String
    let userName: String?
    
    init(userId: String, userName: String? = nil) {
        self.userId = userId
        self.userName = userName
        _viewModel = StateObject(wrappedValue: UserPostsViewModel())
    }
    
    var body: some View {
        VStack {
            if let user = viewModel.user {
                Text(user.nickName)
                    .font(.headline)
                    .padding(.top)
            } else if let name = userName {
                Text(name)
                    .font(.headline)
                    .padding(.top)
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if viewModel.posts.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No posts yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(destination: PostDetailView(postId: post.id)) {
                                PostGridItemView(post: post)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(userName ?? "User Posts")
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
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct PostGridItemView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading) {
            if !post.imageUrls.isEmpty, let url = URL(string: post.imageUrls[0]) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fill)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fill)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fill)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(post.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .padding(.top, 4)
            
            if post.offering == "SOLD_AT_PRICE" && post.price != nil {
                Text("€\(String(format: "%.2f", post.price!))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Free")
                    .font(.caption)
                    .foregroundColor(.green)
            }
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