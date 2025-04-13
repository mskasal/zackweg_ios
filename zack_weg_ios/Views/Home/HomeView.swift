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
        .navigationTitle("home.title".localized)
        .navigationBarTitleDisplayMode(.large)
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
                            NavigationLink(destination: PostDetailView(post: post, fromUserPostsView: true)) {
                                PostCardCompact(post: post)
                            }
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
                            NavigationLink(destination: PostDetailView(post: post)) {
                                PostCardCompact(post: post)
                            }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image with fixed dimensions
            ZStack {
                if !post.imageUrls.isEmpty {
                    AsyncImage(url: URL(string: post.imageUrls[0])) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 120)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 160, height: 120)
                            .overlay {
                                ProgressView()
                            }
                    }
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
            
            // Title
            Text(post.title)
                .fontWeight(.medium)
                .lineLimit(1)
            
            // Price or Free
            if post.offering == "GIVING_AWAY" {
                Text("posts.free".localized)
                    .foregroundColor(.green)
                    .font(.subheadline)
            } else if let price = post.price {
                Text("€\(String(format: "%.2f", price))")
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }
        }
        .frame(width: 160)
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
