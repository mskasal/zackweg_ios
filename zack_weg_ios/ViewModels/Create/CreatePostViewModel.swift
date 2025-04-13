import Foundation
import SwiftUI

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var createdPost: Post?
    @Published var createdPostId: String?
    
    // New properties for immediate image upload
    @Published var imageUploadStates: [String: ImageUploadState] = [:] {
        didSet {
            updateCachedStatuses()
        }
    }
    @Published var uploadedImageUrls: [String] = []
    
    // Cached status values
    @Published private(set) var allImagesUploaded: Bool = false
    @Published private(set) var hasFailedUploads: Bool = false
    
    private let apiService: APIService
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    // Update cached status properties to avoid excessive recalculations
    private func updateCachedStatuses() {
        // Only calculate if we have image states
        if imageUploadStates.isEmpty {
            allImagesUploaded = false
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
    
    // Upload a single image immediately
    func uploadImage(id: String, imageData: Data) {
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
                    let url = try await self.apiService.uploadImage(imageData)
                    
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
    
    // Create post with already uploaded images
    func createPost(
        title: String,
        description: String,
        category: String,
        offering: String,
        price: String?
    ) async throws {
        guard !uploadedImageUrls.isEmpty else {
            throw NSError(domain: "CreatePostViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "No images have been uploaded."])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Convert price string to Double if needed
            let priceDouble: Double? = price.flatMap { priceString in
                return Double(priceString)
            }
            
            // Create the post with the already uploaded image URLs
            let post = try await apiService.createPost(
                title: title,
                description: description,
                categoryId: category,
                offering: offering,
                imageUrls: uploadedImageUrls,
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
    
    // Reset all image upload states
    func resetImageUploads() {
        imageUploadStates.removeAll()
        uploadedImageUrls.removeAll()
        // Reset cached values too
        allImagesUploaded = false
        hasFailedUploads = false
    }
    
    // The computed properties are now removed as they've been replaced with cached values
} 
