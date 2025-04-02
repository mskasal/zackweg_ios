import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @EnvironmentObject private var unreadMessagesViewModel: UnreadMessagesViewModel
    @State private var shouldRefresh = false
    
    var body: some View {
        Group {
            if viewModel.conversations.isEmpty {
                emptyStateView
            } else {
                conversationsList
            }
        }
        .navigationTitle("messages.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchConversations()
        }
        .task {
            await viewModel.fetchConversations()
        }
        .onChange(of: shouldRefresh) { newValue in
            if newValue {
                Task {
                    await viewModel.fetchConversations()
                    shouldRefresh = false
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color.gray.opacity(0.6))
                .padding()
            
            Text("messages.no_conversations".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("messages.empty_state_message".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("messages.explore_to_message".localized)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    private var conversationsList: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                NavigationLink(destination: ConversationDetailView(conversation: conversation)
                    .onDisappear {
                        // When returning from conversation detail, trigger a refresh of conversations
                        shouldRefresh = true
                        // Also refresh the unread count
                        unreadMessagesViewModel.refreshUnreadCount()
                    }
                ) {
                    ConversationRow(conversation: conversation, viewModel: viewModel)
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    @ObservedObject var viewModel: MessagesViewModel
    
    private var hasUnreadMessages: Bool {
        guard let lastMessage = conversation.lastMessage else {
            return false
        }
        
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
        // Check if the last message is unread and not from current user
        return !lastMessage.isRead && lastMessage.senderId != currentUserId
    }
    
    private var unreadCount: Int {
        return viewModel.unreadCount(for: conversation.id)
    }
    
    private var isLoadingCount: Bool {
        return viewModel.isLoadingUnreadCount(for: conversation.id)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with badge
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(conversation.user1.nickName.prefix(1).uppercased())
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                    )
                
                if unreadCount > 0 && !isLoadingCount {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 3, y: -3)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.user1.nickName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(unreadCount > 0 ? .primary : .secondary)
                    
                    Spacer()
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.createdAt.formatted(.relative(presentation: .named)))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage.content)
                        .font(.system(size: 14))
                        .foregroundColor(unreadCount > 0 ? .primary : .gray)
                        .fontWeight(unreadCount > 0 ? .medium : .regular)
                        .lineLimit(1)
                } else {
                    Text("messages.none".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            // Ensure the unread count is loaded when row appears
            if !isLoadingCount && unreadCount == 0 {
                Task {
                    await viewModel.getUnreadCount(for: conversation.id)
                }
            }
        }
    }
}

#Preview {
    MessagesView()
} 
