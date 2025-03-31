import Foundation
import SwiftUI

// These are needed to access Post, PublicUser and APIService 
// from the Models and Services directories
import Foundation

@MainActor
class PostCardViewModel: ObservableObject {
    private let post: Post
    @Published var seller: PublicUser?
    @Published var isLoadingSeller = false
    @Published var error: String?
    
    init(post: Post) {
        self.post = post
    }
    
    func loadSellerInfo() async {
        // Guard against reloading if already loaded or in progress
        guard !isLoadingSeller && seller == nil else { 
            return 
        }
        
        isLoadingSeller = true
        
        do {
            let user = try await APIService.shared.getUserById(post.userId)
            self.seller = user
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoadingSeller = false
    }
    
    func getInitials(for name: String) -> String {
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
} 