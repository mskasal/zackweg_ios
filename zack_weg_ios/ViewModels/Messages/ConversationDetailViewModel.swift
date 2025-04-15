import Foundation

@MainActor
class ConversationDetailViewModel: ObservableObject {
    @Published var conversation: Conversation
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isTyping = false
    @Published var isPostAvailable = true
    
    private let apiService: APIService
    
    var currentUserId: String {
        UserDefaults.standard.string(forKey: "userId") ?? ""
    }
    
    init(conversation: Conversation, apiService: APIService = .shared) {
        self.conversation = conversation
        self.apiService = apiService
        print("📱 ConversationDetailViewModel initialized for conversation: \(conversation.id)")
    }
    
    func fetchMessages() async {
        isLoading = true
        error = nil
        print("📱 Fetching messages for conversation: \(conversation.id)")
        
        do {
            // First check if the post is still available
            do {
                _ = try await apiService.getPostById(conversation.postId)
                isPostAvailable = true
            } catch let error as APIError {
                if case .notFound = error {
                    print("❌ Post is no longer available (404)")
                    isPostAvailable = false
                } else if case .serverError(let code, _) = error, code == 404 {
                    print("❌ Post is no longer available (404)")
                    isPostAvailable = false
                } else {
                    print("❌ Error checking post availability: \(error.localizedDescription)")
                    throw error
                }
            }
            
            // Use the new getConversationWithMessages method
            let conversationWithMessages = try await apiService.getConversationWithMessages(conversationId: conversation.id)
            
            // Update both the conversation and messages
            self.conversation = conversationWithMessages.conversation
            self.messages = conversationWithMessages.messages
            
            print("📱 Successfully loaded \(messages.count) messages")
            
            // Mark conversation as read on the server
            try await markConversationAsRead()
            
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            print("❌ Error fetching messages: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    // New method to mark conversation as read
    func markConversationAsRead() async throws {
        print("📱 Marking conversation as read: \(conversation.id)")
        try await apiService.markConversationAsRead(conversationId: conversation.id)
    }
    
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isTyping = true
        
        do {
            let message = try await apiService.sendMessage(conversationId: conversation.id, content: content)
            // Add the message to our local array
            messages.append(message)
            
            isTyping = false
        } catch {
            self.error = error.localizedDescription
            print("❌ Error sending message: \(error.localizedDescription)")
            isTyping = false
        }
    }
    
    func simulateTyping() {
        guard !isTyping else { return }
        
        isTyping = true
        print("📱 User is typing...")
        
        // In a real app, you would send typing indicator to server
        // Automatically end typing status after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            self.isTyping = false
            print("📱 User stopped typing")
        }
    }
} 
