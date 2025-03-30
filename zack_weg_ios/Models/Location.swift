import Foundation

struct Location: Codable {
    let postalCode: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case postalCode = "postal_code"
        case countryCode = "country_code"
        case latitude
        case longitude
    }
}
