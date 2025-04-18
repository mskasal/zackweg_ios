import Foundation

struct NotificationPreferences: Codable {
    let notificationPreferences: [NotificationPreference]
    
    enum CodingKeys: String, CodingKey {
        case notificationPreferences = "notification_preferences"
    }
}

struct NotificationPreference: Codable, Identifiable {
    var id: String { "\(type.rawValue)_\(channel.rawValue)" }
    let type: NotificationType
    let channel: NotificationChannel
    let enabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case type
        case channel
        case enabled
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case userMessage = "USER_MESSAGE"
    case campaign = "CAMPAIGN"
}

enum NotificationChannel: String, Codable, CaseIterable {
    case email = "EMAIL"
    case mobilePush = "MOBILE_PUSH"
} 