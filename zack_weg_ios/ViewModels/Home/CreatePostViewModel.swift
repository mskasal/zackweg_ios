import Foundation
import SwiftUI

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var error: String?
    @Published var isLoading = false
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
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
} 