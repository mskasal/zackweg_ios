import Foundation
import SwiftUI
import UIKit

@MainActor
class EditPostViewModel: ObservableObject {
    @Published var post: Post?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    
    // Keep existing image URLs
    @Published var imageUrls: [String] = []
    @Published var removedImageUrls: [String] = []
    
    // Status properties
    @Published var status: String = "ACTIVE" // Current status
    @Published var originalStatus: String = "ACTIVE" // Original post status
    
    // Add new properties for immediate image upload approach
    @Published var imageUploadStates: [String: ImageUploadState] = [:] {
        didSet {
            updateCachedStatuses()
        }
    }
    @Published var uploadedImageUrls: [String] = []
    
    // Cached status values
    @Published private(set) var allImagesUploaded: Bool = false
    @Published private(set) var hasFailedUploads: Bool = false
    
    // Constants for image handling
    private let maxImageSize: Int = 5 * 1024 * 1024 // 5MB
    private let allowedImageTypes = ["image/jpeg", "image/png", "image/heic"]
    private let maxImageDimension: CGFloat = 1200 // Max dimension for resizing
    
    private let apiService: APIService
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    // Update cached status properties to avoid excessive recalculations
    private func updateCachedStatuses() {
        // Only calculate if we have image states
        if imageUploadStates.isEmpty {
            allImagesUploaded = true // Default to true when no new uploads
            hasFailedUploads = false
            return
        }
        
        var allUploaded = true
        var hasFailed = false
        
        for state in imageUploadStates.values {
            if case .uploaded = state {
                continue
            } else {
                allUploaded = false
            }
            
            if case .failed = state {
                hasFailed = true
            }
        }
        
        allImagesUploaded = allUploaded
        hasFailedUploads = hasFailed
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
    
    // Upload a single image immediately
    func uploadImage(id: String, imageData: Data) {
        // Validate image size
        guard imageData.count <= maxImageSize else {
            imageUploadStates[id] = .failed(error: "Image is too large. Maximum size is 5MB.")
            return
        }
        
        // Validate and resize image
        guard let uiImage = UIImage(data: imageData), 
              let resizedImageData = resizeImage(uiImage) else {
            imageUploadStates[id] = .failed(error: "Invalid image format")
            return
        }
        
        // Set initial state to "uploading" with 0 progress
        imageUploadStates[id] = .uploading(progress: 0.0)
        
        // Create a true background task 
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate progress updates on background thread
            var progress = 0.0
            let simulateProgress = {
                // Update UI on main thread for each progress step
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    progress += 0.1
                    self.imageUploadStates[id] = .uploading(progress: min(0.9, progress))
                }
            }
            
            // Set up timer for progress simulation (completely non-blocking)
            let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                simulateProgress()
            }
            
            // Start upload process
            Task {
                do {
                    // Actual upload - this is async and shouldn't block
                    let url = try await self.apiService.uploadImage(resizedImageData)
                    
                    // Stop the progress timer
                    timer.invalidate()
                    
                    // Update UI on main thread
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        // Update the state to uploaded with URL
                        self.imageUploadStates[id] = .uploaded(url: url)
                        
                        // Add to our list of uploaded URLs
                        if !self.uploadedImageUrls.contains(url) {
                            self.uploadedImageUrls.append(url)
                        }
                        
                        print("✅ Image uploaded successfully: \(url)")
                    }
                } catch {
                    // Stop the progress timer
                    timer.invalidate()
                    
                    // Handle errors on main thread
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.imageUploadStates[id] = .failed(error: error.localizedDescription)
                        print("❌ Failed to upload image: \(error.localizedDescription)")
                    }
                }
            }
            
            // Start the timer on this runloop
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }
    
    // Retry a failed upload
    func retryImageUpload(id: String, imageData: Data) {
        uploadImage(id: id, imageData: imageData)
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
        
        isSaving = true
        
        do {
            // Combine existing image URLs and newly uploaded URLs
            var finalImageUrls = imageUrls
            finalImageUrls.append(contentsOf: uploadedImageUrls)
            
            // Convert price string to Double if needed
            let priceDouble: Double? = price.flatMap { priceString in
                // Handle German number format (comma as decimal separator)
                let normalizedPrice = priceString.replacingOccurrences(of: ",", with: ".")
                return Double(normalizedPrice)
            }
            
            // Update the post with all data
            try await apiService.updatePost(
                postId: post.id,
                title: title,
                description: description,
                categoryId: categoryId,
                offering: offering,
                imageUrls: finalImageUrls,
                price: priceDouble ?? 0, // Always pass price, default to 0 if nil
                status: status
            )
            
            print("✅ Successfully updated post with ID: \(post.id)")
            
            // Refresh the post data to get the updated version
            let updatedPost = try await apiService.getPostById(post.id)
            self.post = updatedPost
            self.status = updatedPost.status
            isSaving = false
            
            // Reset upload states
            resetImageUploads()
            
            return updatedPost
        } catch {
            isSaving = false
            self.error = error.localizedDescription
            print("❌ Failed to update post: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Reset all image upload states
    func resetImageUploads() {
        imageUploadStates.removeAll()
        uploadedImageUrls.removeAll()
        // Reset cached values
        allImagesUploaded = true // Default to true for edit view
        hasFailedUploads = false
    }
} 
