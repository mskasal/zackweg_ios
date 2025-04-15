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
        } catch let apiError as APIError {
            switch apiError {
            case .notFound:
                self.error = "messages.post_not_available".localized
            case .unauthorized:
                self.error = "error.auth.unauthorized".localized
            case .permissionDenied:
                self.error = "error.user.blocked".localized
            case .badRequest(let message):
                self.error = message ?? "error.input.invalid".localized
            case .serverError(let code, let message):
                self.error = message ?? String(format: "error.server.with_code".localized, code)
            default:
                self.error = apiError.localizedDescription
            }
            throw apiError
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
} 