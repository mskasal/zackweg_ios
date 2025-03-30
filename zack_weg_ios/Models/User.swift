import Foundation

struct User: Codable {
    let id: String
    let email: String
    let nickName: String
    let location: Location
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case nickName = "nick_name"
        case location
    }
}

// PublicUser is for the limited user information returned from public endpoints
struct PublicUser: Codable {
    let id: String
    let nickName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickName = "nick_name"
    }
}
