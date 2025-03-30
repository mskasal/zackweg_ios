import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let createdAt: Date
    let isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case createdAt = "created_at"
        case isRead = "is_read"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        senderId = try container.decode(String.self, forKey: .senderId)
        content = try container.decode(String.self, forKey: .content)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format")
            }
        }
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.conversationId == rhs.conversationId &&
        lhs.senderId == rhs.senderId &&
        lhs.content == rhs.content &&
        lhs.createdAt == rhs.createdAt &&
        lhs.isRead == rhs.isRead
    }
} 