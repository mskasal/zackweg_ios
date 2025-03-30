import SwiftUI
import MapKit

struct MapView: View {
    let posts: [Post]
    let categories: [Category]
    @Environment(\.dismiss) private var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954), // Berlin coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationStack {
            Map(coordinateRegion: $region, annotationItems: posts) { post in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: post.location.latitude,
                    longitude: post.location.longitude
                )) {
                    NavigationLink(destination: PostDetailView(post: post, categories: categories)) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            Text(post.title)
                                .font(.caption)
                                .padding(4)
                                .background(Color.white)
                                .cornerRadius(4)
                                .shadow(radius: 2)
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: [], showsTraffic: false))
            .navigationTitle("explore.map_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MapView(posts: [], categories: [])
}
