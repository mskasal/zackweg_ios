import Foundation
import SwiftUI

@MainActor
class PostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var categories: [Category] = []
    @Published var error: String?
    @Published var isLoading = false
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
        // Fetch user profile to get postal code
        Task {
            await fetchUserProfile()
        }
    }
    
    private func fetchUserProfile() async {
        do {
            let user = try await apiService.getMyProfile()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func fetchCategories() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            categories = try await apiService.getCategories()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func createPost(title: String, description: String, category: String, offering: String, images: [Data], price: String? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let imageUrls = try await uploadImages(images)
        let priceDouble = price.flatMap { Double($0) }
        try await apiService.createPost(
            title: title,
            description: description,
            categoryId: category,
            offering: offering,
            imageUrls: imageUrls,
            price: priceDouble
        )
    }
    
    private func uploadImages(_ images: [Data]) async throws -> [String] {
        var urls: [String] = []
        for image in images {
            let url = try await apiService.uploadImage(image)
            urls.append(url)
        }
        return urls
    }
    
    func reportPost(_ postId: String, reason: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await apiService.reportPost(postId: postId, reason: reason)
    }
    
    func startConversation(postId: String, message: String) async throws -> Conversation {
        return try await APIService.shared.startConversation(postId: postId, message: message)
    }
    
    func sendMessage(conversationId: String, content: String) async throws -> Message {
        return try await APIService.shared.sendMessage(conversationId: conversationId, content: content)
    }
} 
