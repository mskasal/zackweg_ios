import Foundation

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var unreadCounts: [String: Int] = [:] // Map conversation IDs to unread counts
    @Published var loadingUnreadCounts: [String: Bool] = [:] // Track loading state for each conversation
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    func fetchConversations() async {
        isLoading = true
        error = nil
        
        do {
            conversations = try await apiService.getConversations()
            isLoading = false
            
            // After fetching conversations, get unread counts for each
            for conversation in conversations {
                await getUnreadCount(for: conversation.id)
            }
        } catch let apiError as APIError {
            isLoading = false
            switch apiError {
            case .unauthorized:
                self.error = "auth.sign_in_to_view".localized
            case .serverError(let code, let message):
                self.error = message ?? String(format: "error.server.with_code".localized, code)
            default:
                self.error = apiError.localizedDescription
            }
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func getUnreadCount(for conversationId: String) async {
        loadingUnreadCounts[conversationId] = true
        
        do {
            let count = try await apiService.getUnreadCount(conversationId: conversationId)
            unreadCounts[conversationId] = count
            loadingUnreadCounts[conversationId] = false
        } catch let apiError as APIError {
            loadingUnreadCounts[conversationId] = false
            // Default to 0 on error
            unreadCounts[conversationId] = 0
            
            // Log the specific API error
            switch apiError {
            case .notFound:
                print("❌ Conversation \(conversationId) not found")
            case .unauthorized:
                print("❌ Not authorized to access conversation \(conversationId)")
            default:
                print("❌ Error fetching unread count for conversation \(conversationId): \(apiError.localizedDescription)")
            }
        } catch {
            print("❌ Error fetching unread count for conversation \(conversationId): \(error.localizedDescription)")
            loadingUnreadCounts[conversationId] = false
            // Default to 0 on error
            unreadCounts[conversationId] = 0
        }
    }
    
    func isLoadingUnreadCount(for conversationId: String) -> Bool {
        return loadingUnreadCounts[conversationId] ?? false
    }
    
    func unreadCount(for conversationId: String) -> Int {
        return unreadCounts[conversationId] ?? 0
    }
} 