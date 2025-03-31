import SwiftUI
import Foundation

struct ConversationDetailView: View {
    // Store the initial conversation just for the init, but use the one from ViewModel for display
    private let initialConversation: Conversation
    let seller: PublicUser?
    let post: Post?
    @StateObject private var viewModel: ConversationDetailViewModel
    @EnvironmentObject private var unreadMessagesViewModel: UnreadMessagesViewModel
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    init(conversation: Conversation, seller: PublicUser? = nil, post: Post? = nil) {
        self.initialConversation = conversation
        self.seller = seller
        self.post = post
        _viewModel = StateObject(wrappedValue: ConversationDetailViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Seller and Post Info Header
            if let seller = seller, let post = post {
                VStack(spacing: 12) {
                    // Seller info and post thumbnail
                    HStack(spacing: 14) {
                        // Seller avatar
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 42, height: 42)
                            
                            Text(getInitials(for: seller.nickName))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        // Post thumbnail if available
                        if let firstImageUrl = post.imageUrls.first, let url = URL(string: firstImageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(seller.nickName)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(post.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            if post.offering == "SOLD_AT_PRICE" {
                                Text("€\(String(format: "%.2f", post.price!))")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            } else {
                                Text("common.free".localized)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6).opacity(0.6))
            }
            
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
            
            MessageInputView(messageText: $messageText, onSend: {
                Task {
                    await sendMessage()
                }
            })
        }
        .navigationTitle(seller?.nickName ?? viewModel.conversation.user2.nickName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Mark conversation as read when opening the view
            do {
                let conversationId = viewModel.conversation.id
                try await APIService.shared.markConversationAsRead(conversationId: conversationId)
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
        
        let timeInterval = nextMessage.createdAt.timeIntervalSince(currentMessage.createdAt)
        return abs(timeInterval) > 600 // 10 minutes = 600 seconds
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
