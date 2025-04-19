import Foundation

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
    let detail: String?
    
    init(message: String, detail: String? = nil) {
        self.message = message
        self.detail = detail
    }
} 