import SwiftUI
import Combine

@MainActor
class UnreadMessagesViewModel: ObservableObject {
    @Published var unreadCount: Int = 0
    private let apiService: APIService
    private var refreshTask: Task<Void, Never>?
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
        refreshUnreadCount()
    }
    
    func refreshUnreadCount() {
        // Cancel any existing task
        refreshTask?.cancel()
        
        refreshTask = Task {
            do {
                let count = try await apiService.getUnreadMessagesCount()
                self.unreadCount = count
            } catch {
                print("Error fetching unread count: \(error)")
            }
        }
    }
    
    deinit {
        refreshTask?.cancel()
    }
} 