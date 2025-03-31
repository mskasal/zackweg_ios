import Foundation
import MapKit
import SwiftUI

@MainActor
class MapViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var selectedPost: Post?
    @Published var showPostDetail = false
    @Published var mapPosition: MapCameraPosition = .automatic
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.52, longitude: 13.405), // Default to Berlin
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiService: APIService
    var dismiss: (() -> Void)? = nil
    
    init(posts: [Post] = [], apiService: APIService = .shared) {
        self.posts = posts
        self.apiService = apiService
        
        // Initialize with user's location if available
        if let postalCode = UserDefaults.standard.string(forKey: "postalCode"),
           let countryCode = UserDefaults.standard.string(forKey: "countryCode") {
            Task {
                await fetchLocation(postalCode: postalCode, countryCode: countryCode)
            }
        }
    }
    
    func fetchLocation(postalCode: String, countryCode: String) async {
        isLoading = true
        defer { isLoading = false }
        
        // Here you would typically use a geocoding service to convert postal code to coordinates
        // For now, we'll just use the default region
        // In a real implementation, you'd call an API or use Core Location
        
        // Example (pseudocode):
        // let location = try await geocodingService.getCoordinates(postalCode: postalCode, countryCode: countryCode)
        // region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        // mapPosition = .region(region)
    }
    
    func setPosts(_ posts: [Post]) {
        self.posts = posts
        
        // If we have posts, center the map on the first post's location
        if let firstPost = posts.first {
            let center = CLLocationCoordinate2D(
                latitude: firstPost.location.latitude,
                longitude: firstPost.location.longitude
            )
            region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            mapPosition = .region(region)
        }
    }
} 