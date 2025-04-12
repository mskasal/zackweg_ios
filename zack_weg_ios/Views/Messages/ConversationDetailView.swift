import SwiftUI
import Foundation

struct ConversationDetailView: View {
    // Store the initial conversation just for the init, but use the one from ViewModel for display
    private let initialConversation: Conversation
    let post: Post?
    @StateObject private var viewModel: ConversationDetailViewModel
    @EnvironmentObject private var unreadMessagesViewModel: UnreadMessagesViewModel
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    init(conversation: Conversation, post: Post? = nil) {
        self.initialConversation = conversation
        self.post = post
        _viewModel = StateObject(wrappedValue: ConversationDetailViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Header with navigation to Post and User
            ConversationHeaderView(conversation: viewModel.conversation)
                .padding(.vertical, 8)
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else if viewModel.messages.isEmpty {
                            Text("messages.conversation_empty".localized)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(Array(zip(viewModel.messages.indices, viewModel.messages)), id: \.0) { index, message in
                                let isFromCurrentUser = message.senderId == viewModel.currentUserId
                                let isLastInGroup = isLastMessageInGroup(at: index)
                                let showTimestamp = shouldShowTimestamp(at: index)
                                
                                MessageBubbleView(
                                    message: message,
                                    isFromCurrentUser: isFromCurrentUser,
                                    isLastInGroup: isLastInGroup,
                                    showTimestamp: showTimestamp
                                )
                                .id(message.id)
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.messages) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            if !viewModel.isPostAvailable {
                Text("messages.post_not_available".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            MessageInputView(messageText: $messageText, onSend: {
                Task {
                    await sendMessage()
                }
            })
            .disabled(!viewModel.isPostAvailable)
        }
        .task {
            // Mark conversation as read when opening the view
            do {
                try await viewModel.markConversationAsRead()
                // Refresh unread count after marking this conversation as read
                unreadMessagesViewModel.refreshUnreadCount()
            } catch {
                print("Error marking conversation as read: \(error)")
            }
            
            await viewModel.fetchMessages()
        }
    }
    
    private func sendMessage() async {
        guard !messageText.isEmpty else { return }
        await viewModel.sendMessage(messageText)
        messageText = ""
    }
    
    // Helper function to get initials from name
    private func getInitials(for name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1, 
           let firstInitial = components[0].first,
           let lastInitial = components[1].first {
            return "\(firstInitial)\(lastInitial)"
        } else if let firstInitial = components[0].first {
            return String(firstInitial)
        }
        return "?"
    }
    
    // Helper function to determine if a message is the last in a group from the same sender
    private func isLastMessageInGroup(at index: Int) -> Bool {
        guard index < viewModel.messages.count - 1 else { return true }
        
        let currentMessage = viewModel.messages[index]
        let nextMessage = viewModel.messages[index + 1]
        
        return currentMessage.senderId != nextMessage.senderId
    }
    
    // Helper function to determine if a timestamp should be shown for this message
    private func shouldShowTimestamp(at index: Int) -> Bool {
        // Show timestamp on the last message in a group or if it's been more than 10 minutes
        if isLastMessageInGroup(at: index) {
            return true
        }
        
        // Compare timestamps with next message, show timestamp if more than 10 minutes apart
        guard index < viewModel.messages.count - 1 else { return true }
        
        let currentMessage = viewModel.messages[index]
        let nextMessage = viewModel.messages[index + 1]
        
        // Calculate time difference in minutes
        let timeInterval = nextMessage.createdAt.timeIntervalSince(currentMessage.createdAt)
        let minutesDifference = abs(timeInterval) / 60
        
        return minutesDifference >= 10
    }
}

// New Conversation Header Component
struct ConversationHeaderView: View {
    let conversation: Conversation
    @State private var postDetails: Post?
    @State private var otherUser: PublicUser?
    @State private var isLoading = false
    @State private var isInitialized = false
    @State private var isPostAvailable = true
    
    private var isUser1Seller: Bool {
        guard let post = postDetails else { return false }
        return post.user.id == conversation.user1.id
    }
    
    private var otherUserId: String {
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
        return conversation.user1.id == currentUserId ? conversation.user2.id : conversation.user1.id
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 60)
            } else {
                HStack(spacing: 12) {
                    if isPostAvailable {
                        // Post image section
                        if let post = postDetails, !post.imageUrls.isEmpty, let imageUrl = post.imageUrls.first, let url = URL(string: imageUrl) {
                            NavigationLink(destination: PostDetailView(post: post, fromUserPostsView: false)) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        } else {
                            // Placeholder when post is not available
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // Post info section
                        if let post = postDetails {
                            NavigationLink(destination: PostDetailView(post: post, fromUserPostsView: false)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(post.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Text(post.offering == "SOLD_AT_PRICE" ? "common.selling".localized : "common.giving_away".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            // Placeholder when post details not loaded yet
                            VStack(alignment: .leading, spacing: 2) {
                                Text("common.loading".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // User info
                        if let user = otherUser {
                            NavigationLink(destination: UserPostsView(userId: user.id, userName: user.nickName, disablePostNavigation: true)) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.secondary)
                                    Text(user.nickName)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    } else {
                        // When post is not available, show only user info on the left
                        if let user = otherUser {
                            NavigationLink(destination: UserPostsView(userId: user.id, userName: user.nickName, disablePostNavigation: true)) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.secondary)
                                    Text(user.nickName)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text("messages.post_not_available".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground).opacity(0.05))
        .onAppear {
            if !isInitialized {
                isInitialized = true
                loadData()
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        
        Task {
            do {
                // Fetch post details
                do {
                    let post = try await APIService.shared.getPostById(conversation.postId)
                    await MainActor.run {
                        self.postDetails = post
                        self.isPostAvailable = true
                    }
                } catch let error as APIError {
                    if case .serverError(let message) = error, message.contains("404") {
                        print("❌ Post is no longer available (404)")
                        await MainActor.run {
                            self.isPostAvailable = false
                        }
                    } else {
                        throw error
                    }
                }
                
                // Fetch other user's details
                let user = try await APIService.shared.getUserProfile(userId: otherUserId)
                
                await MainActor.run {
                    self.otherUser = user
                    self.isLoading = false
                }
            } catch {
                print("Error loading conversation data: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        let jsonString = """
        {
            "id": "conv-123",
            "user1": {
                "id": "user-123",
                "nick_name": "Me"
            },
            "user2": {
                "id": "user-456",
                "nick_name": "Other"
            },
            "post_id": "post-123",
            "created_at": "2024-03-14T12:00:00.000Z",
            "last_message": null
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let conversation = try! decoder.decode(Conversation.self, from: jsonData)
        
        return ConversationDetailView(conversation: conversation)
    }
} 
