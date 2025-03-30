import Foundation

struct SearchFilters {
    var keyword: String = ""
    var postalCode: String = ""
    var countryCode: String = "DEU"
    var radiusKm: Double = 20.0
    var limit: Int = 10
    var offset: Int = 0
    var categoryId: String = ""
    var offering: String?
} 
