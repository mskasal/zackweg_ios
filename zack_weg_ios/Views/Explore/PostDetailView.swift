import SwiftUI
import UIKit

struct PostDetailView: View {
    // Store the initial post passed in, but use a state variable for display
    private let initialPost: Post
    let fromUserPostsView: Bool
    @EnvironmentObject private var categoryViewModel: CategoryViewModel
    @StateObject private var viewModel: PostDetailViewModel
    @State private var showingMessageSheet = false
    @State private var showingReportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAlert = false
    @State private var alert: Alert?
    @State private var currentPost: Post?
    @Environment(\.dismiss) private var dismiss
    
    init(post: Post, fromUserPostsView: Bool = false) {
        self.initialPost = post
        self.fromUserPostsView = fromUserPostsView
        _currentPost = State(initialValue: post)
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }
    
    private var category: Category? {
        return categoryViewModel.getCategory(byId: currentPost?.categoryId ?? "")
    }
    
    var body: some View {
        Group {
            if let displayPost = currentPost {
                postContent(displayPost)
            } else {
                loadingView
            }
        }
        .onChange(of: viewModel.postDeleted) { deleted in
            if deleted {
                dismiss()
            }
        }
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
                                
                                Text(viewModel.getInitials(for: currentPost?.user.nickName ?? ""))
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(currentPost?.user.nickName ?? "")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
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
                    
                    Text(String(format: "post_detail.send_message_to".localized, currentPost?.user.nickName ?? ""))
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
                // No need to load seller info anymore
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            if let post = currentPost {
                ReportView(postId: post.id)
            }
        }
        .sheet(item: $viewModel.conversation) { conversation in
            if let post = currentPost {
                ConversationDetailView(conversation: conversation, post: post)
            } else {
                ConversationDetailView(conversation: conversation)
            }
        }
        .onAppear {
            // No need to load seller info anymore
        }
        .environmentObject(categoryViewModel)
        .refreshable {
            await viewModel.loadPostDetails()
        }
        .alert(isPresented: $showingAlert) {
            alert ?? Alert(title: Text("Error"), message: Text("Unknown error"))
        }
        .fullScreenCover(isPresented: $viewModel.showingImagePreview) {
            if let post = viewModel.loadedPost {
                PostImagePreviewView(imageUrls: post.imageUrls)
            }
        }
        .disabled(viewModel.isDeleting)
        .overlay {
            if viewModel.isDeleting {
                ZStack {
                    Color.black.opacity(0.4)
                    HStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("post_detail.deleting".localized)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                }
                .ignoresSafeArea()
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .padding()
            Text("post_detail.loading".localized)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func postContent(_ post: Post) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Image Gallery - only this part ignores the safe area
                ZStack(alignment: .topTrailing) {
                    TabView {
                        if post.imageUrls.isEmpty {
                            // Placeholder when no images available
                            EmptyImagePlaceholderView(height: 350)
                        } else {
                            ForEach(post.imageUrls, id: \.self) { imageUrl in
                                OptimizedAsyncImageView(
                                    imageUrl: imageUrl,
                                    height: 350,
                                    onTapAction: { viewModel.showingImagePreview = true }
                                )
                            }
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
                                Text(String(post.price!).asPriceText())
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            } else if post.offering == "GIVING_AWAY" {
                                HStack(spacing: 4) {
                                    Image(systemName: "gift.fill")
                                        .font(.caption)
                                    Text("common.free".localized)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green)
                                .cornerRadius(8)
                            }
                        }
                        
                        // Category
                        if let category = category {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue.opacity(0.8))
                                Text(category.title)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Seller avatar and nickname - simple display
                    if viewModel.isOwner {
                        // Show "Your Post" indicator when user is the owner
                        HStack(spacing: 8) {
                            // Avatar icon with checkmark
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: "person.fill.checkmark")
                                    .font(.footnote)
                                    .foregroundColor(.green)
                            }
                            
                            // Your Post text
                            Text("post_detail.your_post".localized)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    } else if post.user.id != "" {
                        if fromUserPostsView {
                            // Just show seller info without navigation when coming from UserPostsView
                            HStack(spacing: 8) {
                                // Avatar icon
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 30, height: 30)
                                    
                                    Image(systemName: "person.circle.fill")
                                        .font(.footnote)
                                        .foregroundColor(.blue)
                                }
                                
                                // Nickname
                                Text(post.user.nickName)
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        } else {
                            // Include navigation to PublicUserView instead of UserPostsView
                            NavigationLink(destination: PublicUserView(userId: post.user.id, nickName: post.user.nickName)) {
                                HStack(spacing: 8) {
                                    // Avatar icon
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 30, height: 30)
                                        
                                        Image(systemName: "person.circle.fill")
                                            .font(.footnote)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    // Nickname
                                    Text(post.user.nickName)
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                        
                                    Spacer()
                                    
                                    // Forward chevron
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    
                    // Location and Date section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            // Location with map pin
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
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
                    if viewModel.isOwner {
                        VStack(spacing: 16) {
                            Spacer()
                                .frame(height: 16)
                                
                            // Add edit button
                            NavigationLink(
                                destination: EditPostView(
                                    postId: post.id,
                                    updatedPost: Binding(
                                        get: { nil },
                                        set: { if let newPost = $0 { 
                                            self.currentPost = newPost
                                            viewModel.loadedPost = newPost 
                                        }}
                                    )
                                )
                            ) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("posts.edit".localized)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .font(.subheadline)
                            }
                            
                            Button(action: {
                                showingDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("posts.delete".localized)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .font(.subheadline)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Spacer()
                                .frame(height: 16)
                                
                            Button(action: {
                                showingMessageSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("post_detail.message_seller".localized)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .font(.subheadline)
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
                                .padding(.vertical, 14)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                                .font(.subheadline)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("posts.delete".localized, isPresented: $showingDeleteConfirmation) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("common.delete".localized, role: .destructive) {
                Task {
                    await viewModel.deletePost()
                }
            }
        } message: {
            Text("posts.delete_confirmation".localized)
        }
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
