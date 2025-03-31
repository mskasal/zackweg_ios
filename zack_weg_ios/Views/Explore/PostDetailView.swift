import SwiftUI

struct PostDetailView: View {
    let post: Post
    @EnvironmentObject private var categoryViewModel: CategoryViewModel
    @StateObject private var viewModel: PostDetailViewModel
    @State private var showingMessageSheet = false
    @State private var showingReportSheet = false
    @Environment(\.dismiss) private var dismiss
    
    init(post: Post) {
        self.post = post
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }
    
    private var category: Category? {
        categoryViewModel.getCategory(byId: post.categoryId)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Image Gallery - only this part ignores the safe area
                ZStack(alignment: .topTrailing) {
                    TabView {
                        ForEach(post.imageUrls, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl), 
                                       transaction: Transaction(animation: .easeInOut)) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                                .scaleEffect(1.5)
                                        )
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .transition(.opacity)
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.largeTitle)
                                                .foregroundColor(.red)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(height: 350)
                            .clipped()
                        }
                    }
                    .frame(height: 350)
                    .tabViewStyle(PageTabViewStyle())
                    
                    // Status badge has been removed
                }
                .edgesIgnoringSafeArea(.top) // Only apply to this ZStack
                
                VStack(alignment: .leading, spacing: 24) {
                    // Title and Price section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center) {
                            Text(post.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if post.offering == "SOLD_AT_PRICE" {
                                Text("€\(String(format: "%.2f", post.price!))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            } else if post.offering == "GIVING_AWAY" {
                                HStack(spacing: 6) {
                                    Image(systemName: "gift.fill")
                                        .font(.subheadline)
                                    Text("common.free".localized)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Category
                        if let category = category {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue.opacity(0.8))
                                Text(category.title)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    
                    // Seller avatar and nickname - simple display
                    if let seller = viewModel.seller {
                        HStack(spacing: 8) {
                            // Avatar icon
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            
                            // Nickname
                            Text(seller.nickName)
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Location and Date section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("post_detail.details".localized)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            // Location with map pin
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                Text(post.location.postalCode)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Posted date with calendar icon
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(String(format: "post_detail.posted_time_ago".localized, viewModel.timeAgo(from: post.createdAt)))
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    // Description section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("post_detail.description".localized)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text(post.description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Action Buttons
                    if !viewModel.isOwner {
                        VStack(spacing: 16) {
                            Button(action: {
                                showingMessageSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("post_detail.message_seller".localized)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingReportSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                    Text("post_detail.report_post".localized)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMessageSheet) {
            NavigationStack {
                VStack(spacing: 16) {
                    // Seller Profile Section - Simplified
                    VStack(spacing: 12) {
                        // Seller Avatar and Name
                        HStack(spacing: 14) {
                            // Profile Image
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                
                                if viewModel.isLoadingSeller {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text(viewModel.getInitials(for: viewModel.seller?.nickName ?? "User"))
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                if viewModel.isLoadingSeller {
                                    Text("common.loading".localized)
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(viewModel.seller?.nickName ?? "Seller")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Text("post_detail.new_message".localized)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(String(format: "post_detail.send_message_to".localized, viewModel.seller?.nickName ?? "post_detail.the_seller".localized))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    TextEditor(text: $viewModel.messageText)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
        
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                    
                    HStack(spacing: 16) {
                        Button("common.cancel".localized) {
                            showingMessageSheet = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        
                        Button("common.send".localized) {
                            Task {
                                await viewModel.sendMessage()
                                showingMessageSheet = false
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.messageText.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(viewModel.messageText.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding(.bottom, 20)
            }
            .presentationDetents([.height(480)]) // Slightly reduced height since we removed product info
            .task {
                // Load seller information when sheet appears
                await viewModel.loadSellerInfo()
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportView(postId: post.id)
        }
        .sheet(item: $viewModel.conversation) { conversation in
            ConversationDetailView(conversation: conversation, seller: viewModel.seller, post: post)
        }
        .onAppear {
            // Load seller information when view appears
            Task {
                await viewModel.loadSellerInfo()
            }
        }
        .environmentObject(categoryViewModel)
    }
}

#Preview {
    NavigationStack {
        let jsonString = """
        {
            "id": "1",
            "title": "Sample Post",
            "description": "This is a sample post description that goes into detail about the item being offered. The seller has provided multiple paragraphs of information to help potential buyers understand what they are looking at.",
            "category_id": "1",
            "offering": "SOLD_AT_PRICE",
            "price": 29.99,
            "status": "ACTIVE",
            "image_urls": ["https://example.com/image.jpg"],
            "location": {
                "postal_code": "12345",
                "country_code": "DEU",
                "latitude": 52.520008,
                "longitude": 13.404954
            },
            "created_at": "2024-03-26T12:00:00Z",
            "updated_at": "2024-03-26T12:00:00Z",
            "user_id": "user1"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let post = try! decoder.decode(Post.self, from: jsonData)
        
        return PostDetailView(post: post)
    }
} 
