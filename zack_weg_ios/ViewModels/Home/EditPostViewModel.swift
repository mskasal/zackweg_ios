import Foundation
import SwiftUI
import UIKit

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
    @Published var status: String = "ACTIVE" // Current status
    @Published var originalStatus: String = "ACTIVE" // Original post status
    @Published var uploadProgress: Double = 0
    @Published var currentUploadIndex: Int = 0
    @Published var totalUploads: Int = 0
    @Published var isUploading = false
    @Published var failedUploads: [(index: Int, data: Data)] = []  // Track failed uploads for retry
    
    // Constants for image handling
    private let maxImageSize: Int = 5 * 1024 * 1024 // 5MB
    private let allowedImageTypes = ["image/jpeg", "image/png", "image/heic"]
    private let maxImageDimension: CGFloat = 1200 // Max dimension for resizing
    
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
            
            // Set current status and save original status
            if let postStatus = post?.status {
                status = postStatus
                originalStatus = postStatus // Store original status for change detection
            }
            
            print("✅ Successfully loaded post with ID: \(postId) for editing")
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to load post: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    // Add a new image to be uploaded with validation
    func addImage(_ data: Data) -> Bool {
        // Validate image size
        guard data.count <= maxImageSize else {
            error = "Image is too large. Maximum size is 5MB."
            return false
        }
        
        // Validate image type
        if let uiImage = UIImage(data: data), let resizedImageData = resizeImage(uiImage) {
            newImages.append(resizedImageData)
            return true
        } else {
            error = "Invalid image format. Please use JPEG or PNG images."
            return false
        }
    }
    
    // Resize image to reduce memory usage and upload size
    private func resizeImage(_ image: UIImage) -> Data? {
        let originalSize = image.size
        var newSize = originalSize
        
        // Check if image needs resizing
        if originalSize.width > maxImageDimension || originalSize.height > maxImageDimension {
            if originalSize.width > originalSize.height {
                let ratio = maxImageDimension / originalSize.width
                newSize = CGSize(width: maxImageDimension, height: originalSize.height * ratio)
            } else {
                let ratio = maxImageDimension / originalSize.height
                newSize = CGSize(width: originalSize.width * ratio, height: maxImageDimension)
            }
        }
        
        // If no resize needed, return original data with compression
        if newSize == originalSize {
            return image.jpegData(compressionQuality: 0.8)
        }
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: 0.8)
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
    
    // Reset all error and progress states
    func resetState() {
        error = nil
        uploadProgress = 0
        currentUploadIndex = 0
        totalUploads = 0
        isUploading = false
        failedUploads = []
    }
    
    // Retry failed uploads
    func retryFailedUploads() async -> [String] {
        guard !failedUploads.isEmpty else { return [] }
        
        isUploading = true
        var successfulUrls: [String] = []
        
        totalUploads = failedUploads.count
        let failedCopy = failedUploads // Copy to avoid mutation during enumeration
        failedUploads = [] // Clear the failed uploads list
        
        for (index, failedUpload) in failedCopy.enumerated() {
            currentUploadIndex = index + 1
            uploadProgress = Double(index) / Double(failedCopy.count)
            
            do {
                let url = try await apiService.uploadImage(failedUpload.data)
                successfulUrls.append(url)
            } catch {
                // If it fails again, add it back to the failed uploads
                failedUploads.append(failedUpload)
                self.error = "Failed to upload image \(index + 1) on retry: \(error.localizedDescription)"
            }
        }
        
        uploadProgress = 1.0
        isUploading = false
        return successfulUrls
    }
    
    // Update the post with edited data
    func updatePost(
        title: String,
        description: String,
        categoryId: String,
        offering: String,
        price: String?,
        status: String
    ) async throws -> Post {
        guard let post = post else {
            throw NSError(domain: "EditPostViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "No post loaded for editing"])
        }
        
        resetState()
        isSaving = true
        
        do {
            // First upload any new images
            var updatedImageUrls = imageUrls
            totalUploads = newImages.count
            
            if !newImages.isEmpty {
                isUploading = true
                
                for (index, imageData) in newImages.enumerated() {
                    currentUploadIndex = index + 1
                    uploadProgress = Double(index) / Double(newImages.count)
                    
                    do {
                        let url = try await apiService.uploadImage(imageData)
                        updatedImageUrls.append(url)
                    } catch {
                        // Track failed uploads for potential retry
                        failedUploads.append((index: index, data: imageData))
                        
                        // Continue with other uploads instead of failing completely
                        print("⚠️ Failed to upload image \(index + 1): \(error.localizedDescription)")
                    }
                }
                
                // If there are any failed uploads, offer a chance to retry
                if !failedUploads.isEmpty {
                    self.error = "Failed to upload \(failedUploads.count) images. You can tap 'Retry Failed Uploads' to try again."
                    
                    // We'll continue with successful uploads
                    print("⚠️ Some uploads failed. Continuing with successful uploads.")
                }
                
                uploadProgress = 1.0
                isUploading = false
            }
            
            // Retry any previously failed uploads from the past
            if !failedUploads.isEmpty {
                let retryUrls = await retryFailedUploads()
                updatedImageUrls.append(contentsOf: retryUrls)
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
            let updatedPost = try await apiService.getPostById(post.id)
            self.post = updatedPost
            self.status = updatedPost.status
            isSaving = false
            
            // Clean up temporary data
            newImages = []
            
            return updatedPost
            
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to update post: \(error.localizedDescription)")
            isSaving = false
            throw error
        }
    }
    
    // Synchronize image arrays to ensure consistency
    func synchronizeImageArrays() {
        // Make sure no duplicates exist between new images and image URLs
        if !newImages.isEmpty && !imageUrls.isEmpty {
            // Logic to compare and deduplicate would go here
            // For simple synchronization, we just ensure the arrays are in good state
            print("📊 Synchronizing image arrays: \(imageUrls.count) existing URLs, \(newImages.count) new images")
        }
    }
    
    // Cleanup resources when view disappears
    func cleanup() {
        // Clear temporary image data to free up memory
        newImages = []
        imagePreviews = []
        resetState()
    }
} 