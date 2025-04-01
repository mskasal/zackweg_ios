import SwiftUI

struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = CreatePostViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // My Posts section
            VStack(spacing: 12) {
                HStack {
                    Text("posts.my_posts".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                if let userId = UserDefaults.standard.string(forKey: "userId") {
                    NavigationLink(destination: UserPostsView(userId: userId, userName: "posts.my_posts".localized)) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                            
                            HStack(spacing: 15) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("posts.view_my_posts".localized)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("posts.see_all_items".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                            .padding()
                        }
                        .frame(height: 100)
                    }
                    .padding(.horizontal)
                } else {
                    Text("posts.sign_in_to_view".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            
            Divider()
                .padding(.horizontal)
            
            // Create Post View
            CreatePostView()
                .padding(.top, 8)
        }
    }
}

#Preview {
    HomeView(authViewModel: AuthViewModel())
}
