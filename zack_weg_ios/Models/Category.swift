import Foundation

struct Category: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let parentId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case parentId = "parent_id"
    }
    
    // Implement hash(into:) method for Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement == operator for Equatable conformance
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id
    }
}

// Extension to support hierarchical categories
extension Category {
    // Determine if this is a top-level category
    var isTopLevel: Bool {
        return parentId == nil
    }
    
    // Get child categories from a list of all categories
    func getChildren(from allCategories: [Category]) -> [Category] {
        return allCategories.filter { $0.parentId == self.id }
    }
    
    // Check if this category has any children in the provided list
    func hasChildren(in allCategories: [Category]) -> Bool {
        return allCategories.contains(where: { $0.parentId == self.id })
    }
} 
