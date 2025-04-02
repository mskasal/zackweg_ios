import Foundation
import SwiftUI

@MainActor
class EditPostViewModel: ObservableObject {
    @Published var post: Post?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var imagePreviews: [Data] = []
    @Published var imageUrls: [String] = []
    @Published var removedImageUrls: [String] = []
    @Published var newImages: [Data] = []
    @Published var status: String = "ACTIVE" // Default status
    
    private let apiService: APIService
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    // Load post data for editing
    func loadPost(postId: String) async {
        isLoading = true
        error = nil
        
        do {
            post = try await apiService.getPostById(postId)
            
            // Store the image URLs separately for tracking
            imageUrls = post?.imageUrls ?? []
            
            // Set current status
            if let postStatus = post?.status {
                status = postStatus
            }
            
            print("✅ Successfully loaded post with ID: \(postId) for editing")
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to load post: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    // Add a new image to be uploaded
    func addImage(_ data: Data) {
        newImages.append(data)
    }
    
    // Remove an existing image URL
    func removeImage(at index: Int) {
        if index < imageUrls.count {
            let url = imageUrls.remove(at: index)
            removedImageUrls.append(url)
        }
    }
    
    // Remove a new image that hasn't been uploaded yet
    func removeNewImage(at index: Int) {
        if index < newImages.count {
            newImages.remove(at: index)
        }
    }
    
    // Update the post with edited data
    func updatePost(
        title: String,
        description: String,
        categoryId: String,
        offering: String,
        price: String?,
        status: String
    ) async throws {
        guard let post = post else {
            throw NSError(domain: "EditPostViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "No post loaded for editing"])
        }
        
        isSaving = true
        error = nil
        
        do {
            // First upload any new images
            var updatedImageUrls = imageUrls
            
            for imageData in newImages {
                let url = try await apiService.uploadImage(imageData)
                updatedImageUrls.append(url)
            }
            
            // Convert price string to Double if needed
            let priceDouble: Double? = price.flatMap { priceString in
                return Double(priceString)
            }
            
            // Update the post with all data
            try await apiService.updatePost(
                postId: post.id,
                title: title,
                description: description,
                categoryId: categoryId,
                offering: offering,
                imageUrls: updatedImageUrls,
                price: priceDouble ?? 0, // Always pass price, default to 0 if nil
                status: status
            )
            
            print("✅ Successfully updated post with ID: \(post.id)")
            
            // Refresh the post data to get the updated version
            self.post = try await apiService.getPostById(post.id)
            self.status = self.post?.status ?? "ACTIVE"
            isSaving = false
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to update post: \(error.localizedDescription)")
            isSaving = false
            throw error
        }
    }
} 