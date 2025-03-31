import Foundation
import SwiftUI

// These are needed to access Post, PublicUser and APIService 
// from the Models and Services directories
import Foundation

@MainActor
class PostCardViewModel: ObservableObject {
    private let post: Post
    @Published var error: String?
    
    init(post: Post) {
        self.post = post
    }
    
    var isOwner: Bool {
        UserDefaults.standard.string(forKey: "userId") == post.userId
    }
} 