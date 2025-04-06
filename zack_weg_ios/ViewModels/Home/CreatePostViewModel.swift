import Foundation
import SwiftUI

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var createdPost: Post?
    @Published var createdPostId: String?
    
    private let apiService: APIService
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    func createPost(
        title: String,
        description: String,
        category: String,
        offering: String,
        images: [Data],
        price: String?
    ) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // First upload all images
            var imageUrls: [String] = []
            for imageData in images {
                let url: String = try await apiService.uploadImage(imageData)
                imageUrls.append(url)
            }
            
            // Convert price string to Double if needed
            let priceDouble: Double? = price.flatMap { priceString in
                return Double(priceString)
            }
            
            // Create the post with the uploaded image URLs
            let post = try await apiService.createPost(
                title: title,
                description: description,
                categoryId: category,
                offering: offering,
                imageUrls: imageUrls,
                price: priceDouble
            )
            
            // Store the created post and its ID
            self.createdPost = post
            self.createdPostId = post.id
            
            print("✅ Post created successfully: ID \(post.id)")
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to create post: \(error.localizedDescription)")
            throw error
        }
    }
} 