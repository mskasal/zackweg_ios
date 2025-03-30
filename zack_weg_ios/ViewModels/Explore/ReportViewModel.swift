import Foundation

enum ReportReason: String, CaseIterable {
    case inappropriateContent = "INAPPROPRIATE_CONTENT"
    case spam = "SPAM"
    case misleadingInformation = "MISLEADING_INFORMATION"
    case offensiveBehavior = "OFFENSIVE_BEHAVIOR"
    case prohibitedItems = "PROHIBITED_ITEMS"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .inappropriateContent: return "Inappropriate Content"
        case .spam: return "Spam"
        case .misleadingInformation: return "Misleading Information"
        case .offensiveBehavior: return "Offensive Behavior"
        case .prohibitedItems: return "Prohibited Items"
        case .other: return "Other"
        }
    }
}

@MainActor
class ReportViewModel: ObservableObject {
    let postId: String
    @Published var selectedReason: ReportReason = .inappropriateContent
    @Published var additionalComment = ""
    @Published var error: String?
    @Published var isLoading = false
    @Published var isSuccess = false
    
    private let apiService: APIService
    
    init(postId: String, apiService: APIService = .shared) {
        self.postId = postId
        self.apiService = apiService
    }
    
    func submitReport() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await apiService.reportPost(postId: postId, reason: selectedReason.rawValue)
            isSuccess = true
        } catch {
            self.error = error.localizedDescription
            isSuccess = false
        }
    }
} 