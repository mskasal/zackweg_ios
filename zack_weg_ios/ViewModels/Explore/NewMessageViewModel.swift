import Foundation

@MainActor
class NewMessageViewModel: ObservableObject {
    @Published var error: String?
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    func startConversation(postId: String, message: String) async throws -> Conversation {
        do {
            return try await apiService.startConversation(postId: postId, message: message)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
} 