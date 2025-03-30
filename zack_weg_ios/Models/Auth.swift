import Foundation

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let location: Location
    let nickName: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case location
        case nickName = "nick_name"
    }
}

struct TokenResponse: Codable {
    let token: String
}

struct ErrorResponse: Codable {
    let message: String
} 
