//
//  BlockedUser.swift
//  zack_weg_ios
//
//  Created by Mustafa Samed Kasal on 25.03.25.
//

import Foundation

struct BlockedUser: Codable, Identifiable {
    let blockerUserId: String
    let blockedUserId: String
    let reason: BlockReason
    let createdAt: Date
    
    var id: String { blockedUserId }
    
    enum CodingKeys: String, CodingKey {
        case blockerUserId = "blocker_user_id"
        case blockedUserId = "blocked_user_id"
        case reason
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blockerUserId = try container.decode(String.self, forKey: .blockerUserId)
        blockedUserId = try container.decode(String.self, forKey: .blockedUserId)
        
        // Decode the reason string and convert to enum
        let reasonString = try container.decode(String.self, forKey: .reason)
        reason = BlockReason(rawValue: reasonString) ?? .other
        
        // Handle ISO8601 date format with timezone
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string \(dateString) does not match expected format.")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(blockerUserId, forKey: .blockerUserId)
        try container.encode(blockedUserId, forKey: .blockedUserId)
        try container.encode(reason.rawValue, forKey: .reason)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: createdAt)
        try container.encode(dateString, forKey: .createdAt)
    }
}

enum BlockReason: String, Codable, CaseIterable {
    case harassment = "HARASSMENT"
    case spam = "SPAM"
    case inappropriateContent = "INAPPROPRIATE_CONTENT"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .harassment: 
            return "report.reason.offensive_behavior".localized
        case .spam: 
            return "report.reason.spam".localized
        case .inappropriateContent: 
            return "report.reason.inappropriate_content".localized
        case .other: 
            return "report.reason.other".localized
        }
    }
} 