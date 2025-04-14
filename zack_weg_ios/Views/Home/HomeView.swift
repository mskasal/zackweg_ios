import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top banner section - redirects to explore
                exploreSection
                
                // My Posts section
                myPostsSection
                
                // Near You section
                nearbyPostsSection
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .refreshable {
            await viewModel.refreshAll()
        }
        .task {
            await viewModel.refreshAll()
        }
        .overlay {
            if viewModel.errorMessage != nil {
                Text(viewModel.errorMessage!)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding()
            }
        }
    }
    
    // Explore/Discovery section at the top
    private var exploreSection: some View {
        NavigationLink(destination: ExploreView()) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 160)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("home.discover_items".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("home.find_nearby".localized)
                        .font(.subheadline)
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding()
            }
        }
        .padding(.top, 8)
    }
    
    // My Posts horizontal section
    private var myPostsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("home.my_posts".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: UserPostsView(userId: UserDefaults.standard.string(forKey: "userId") ?? "")) {
                    Text("home.see_all".localized)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.isLoadingMyPosts {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else if viewModel.myPosts.isEmpty {
                Text("home.no_posts".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.myPosts) { post in
                            PostCardCompact(post: post)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.trailing, 4) // Add trailing padding to balance the last item
                }
            }
        }
    }
    
    // Near You horizontal section
    private var nearbyPostsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("home.near_you".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: ExploreView()) {
                    Text("home.see_all".localized)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.isLoadingNearbyPosts {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else if viewModel.nearbyPosts.isEmpty {
                Text("home.no_nearby".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.nearbyPosts) { post in
                            PostCardCompact(post: post)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.trailing, 4) // Add trailing padding to balance the last item
                }
            }
        }
    }
}

// Compact post card for horizontal scrolling
struct PostCardCompact: View {
    let post: Post
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Image with fixed dimensions
                ZStack {
                    if !post.imageUrls.isEmpty {
                        OptimizedAsyncImageView(
                            imageUrl: post.imageUrls[0],
                            height: 120
                        )
                        .frame(width: 160, height: 120)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 160, height: 120)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                    }
                }
                .frame(width: 160, height: 120)
                .cornerRadius(8)
                
                // Title - updated to use primary color instead of blue
                Text(post.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                // Price or Free
                if post.offering == "GIVING_AWAY" {
                    Text("posts.free".localized)
                        .foregroundColor(.green)
                        .font(.subheadline)
                } else if let price = post.price {
                    Text(String(price).asPriceText())
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
            }
            .frame(width: 160)
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Transparent overlay that handles navigation
            NavigationLink(
                destination: PostDetailView(post: post),
                isActive: $isActive
            ) {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: 160, height: 180)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onTapGesture {
            isActive = true
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
