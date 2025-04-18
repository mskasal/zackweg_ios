import Foundation
import SwiftUI

@MainActor
class CategoryViewModel: ObservableObject {
    static let shared = CategoryViewModel()
    
    @Published var categories: [Category] = []
    @Published var topLevelCategories: [Category] = []
    @Published var subCategories: [String: [Category]] = [:]
    @Published var error: String?
    @Published var isLoading = false
    
    private let apiService: APIService
    
    private init(apiService: APIService = .shared) {
        self.apiService = apiService
        // Fetch categories on initialization
        Task {
            await fetchCategories()
        }
    }
    
    func fetchCategories() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            categories = try await apiService.getCategories()
            
            // Organize categories hierarchically
            topLevelCategories = categories.filter { $0.isTopLevel }
            
            // Group subcategories by parent ID
            subCategories = Dictionary(grouping: categories.filter { !$0.isTopLevel }, 
                                     by: { $0.parentId! })
            
        } catch {
            self.error = "Failed to load categories: \(error.localizedDescription)"
            print("Error fetching categories: \(error)")
        }
    }
    
    // Helper method to get child categories for a specific parent
    func getChildCategories(for parentId: String) -> [Category] {
        return subCategories[parentId] ?? []
    }
    
    // Helper method to check if a category has children
    func hasChildren(for categoryId: String) -> Bool {
        return !getChildCategories(for: categoryId).isEmpty
    }
    
    // Helper method to get a category by ID
    func getCategory(byId id: String) -> Category? {
        return categories.first { $0.id == id }
    }
    
    // Helper method to get parent category for a given category
    func getParentCategory(for categoryId: String) -> Category? {
        guard let category = getCategory(byId: categoryId),
              let parentId = category.parentId else {
            return nil
        }
        return getCategory(byId: parentId)
    }
    
    // Helper method to get all categories in a hierarchy (parent and all its children)
    func getAllCategoriesInHierarchy(for categoryId: String) -> [Category] {
        var result: [Category] = []
        if let category = getCategory(byId: categoryId) {
            result.append(category)
            result.append(contentsOf: getChildCategories(for: categoryId))
        }
        return result
    }
    
    // Helper method to get categories with the selected category first
    func getSortedByCategoryId(_ categoryId: String) -> [Category] {
        guard !categoryId.isEmpty, let selectedCategory = getCategory(byId: categoryId) else {
            return categories // Return original list if category not found or no selection
        }
        
        // Create new array with selected category first, then all others (excluding selected)
        var sortedCategories = [selectedCategory]
        sortedCategories.append(contentsOf: categories.filter { $0.id != categoryId })
        
        return sortedCategories
    }
} 
