import Foundation

enum PostOffering: String, Codable, CaseIterable {
    case givingAway = "GIVING_AWAY"
    case soldAtPrice = "SOLD_AT_PRICE"
}

struct PostUser: Codable {
    let id: String
    let nickName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickName = "nick_name"
    }
}

struct Post: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let categoryId: String
    let offering: String
    let price: Double?
    let status: String
    let imageUrls: [String]
    let location: Location
    let user: PostUser
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case categoryId = "category_id"
        case offering
        case price
        case status
        case imageUrls = "image_urls"
        case location
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        offering = try container.decode(String.self, forKey: .offering)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        status = try container.decode(String.self, forKey: .status)
        imageUrls = try container.decode([String].self, forKey: .imageUrls)
        location = try container.decode(Location.self, forKey: .location)
        user = try container.decode(PostUser.self, forKey: .user)
        
        let formatter = ISO8601DateFormatter()
        // Handle updated at date string
        let updatedAtDateString = try container.decode(String.self, forKey: .updatedAt)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: updatedAtDateString) {
            updatedAt = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .updatedAt, in: container, debugDescription: "Invalid date format")
        }
        
        // Handle created at date string
        let createdAtDateString = try container.decode(String.self, forKey: .createdAt)
        
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: createdAtDateString) {
            createdAt = date
        } else {
            // Fallback to simpler format if fractional seconds are not present
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: createdAtDateString) {
                createdAt = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format")
            }
        }
    }
    
    // Computed property to maintain backward compatibility
    var userId: String {
        user.id
    }
}
