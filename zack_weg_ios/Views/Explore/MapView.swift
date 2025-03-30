import SwiftUI
import MapKit

struct PostAnnotationView: View {
    let post: Post
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                if isSelected {
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
}

struct PostListItemView: View {
    let post: Post
    let categories: [Category]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let category = categories.first(where: { $0.id == post.categoryId }) {
                        Text(category.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
        }
    }
}

struct PostDetailCardView: View {
    let post: Post
    let categories: [Category]
    @Binding var showDetail: Bool
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .font(.headline)
                
                HStack {
                    if let category = categories.first(where: { $0.id == post.categoryId }) {
                        Text(category.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("View Details") {
                        showDetail = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 3)
            .padding()
        }
    }
}

struct VisiblePostsListView: View {
    let posts: [Post]
    let categories: [Category]
    let onSelectPost: (Post) -> Void
    let isZoomedInEnough: Bool
    
    @State private var listVisible = false
    @State private var appearingItems: Set<String> = []
    @State private var lastPostCount: Int = 0
    @State private var lastPostIds: [String] = []
    
    var body: some View {
        VStack {
            Spacer()
            
            listContentView
        }
        .onAppear {
            updatePostState()
            animateListAppearance()
        }
        .onChange(of: isZoomedInEnough) { newValue in
            handleZoomChange(newValue)
        }
        .onChange(of: posts.count) { _ in
            handlePostsChange()
        }
        .task {
            let currentIds = posts.map { $0.id }
            if currentIds != lastPostIds {
                lastPostIds = currentIds
                handlePostsChange()
            }
        }
    }
    
    private func updatePostState() {
        lastPostCount = posts.count
        lastPostIds = posts.map { $0.id }
    }
    
    private var listContentView: some View {
        VStack(spacing: 8) {
            ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                listItemView(for: post, at: index)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .offset(y: listVisible ? 0 : 50)
        .opacity(listVisible ? 1 : 0)
    }
    
    private func listItemView(for post: Post, at index: Int) -> some View {
        PostListItemView(
            post: post,
            categories: categories,
            action: { onSelectPost(post) }
        )
        .opacity(appearingItems.contains(post.id) ? 1 : 0)
        .offset(y: appearingItems.contains(post.id) ? 0 : 20)
        .onAppear {
            animateItemAppearance(post: post, index: index)
        }
        .onDisappear {
            appearingItems.remove(post.id)
        }
    }
    
    private func animateItemAppearance(post: Post, index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.1)) {
            appearingItems.insert(post.id)
        }
    }
    
    private func animateListAppearance() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            listVisible = true
        }
    }
    
    private func handleZoomChange(_ isZoomedIn: Bool) {
        if isZoomedIn && !posts.isEmpty {
            animateListAppearance()
        } else {
            withAnimation {
                listVisible = false
            }
        }
    }
    
    private func handlePostsChange() {
        updatePostState()
        if !posts.isEmpty && isZoomedInEnough && !listVisible {
            animateListAppearance()
        }
    }
}

struct MapView: View {
    let posts: [Post]
    let categories: [Category]
    @Environment(\.dismiss) private var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954), // Berlin coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedPost: Post?
    @State private var showPostDetail = false
    @State private var listVisible = false
    @State private var appearingItems: Set<String> = []
    @State private var mapPosition: MapCameraPosition = .automatic
    
    // Check if zoom level is close enough to show the list
    private var isZoomedInEnough: Bool {
        // Consider zoomed in when latitudeDelta is less than 0.05 (approximately city level)
        return region.span.latitudeDelta < 0.05
    }
    
    // Get posts that are likely visible in the current view
    private var visiblePosts: [Post] {
        guard !posts.isEmpty else { return [] }
        
        // Filter posts that are in the visible region with some padding
        let visiblePosts = posts.filter { post in
            let postLat = post.location.latitude
            let postLong = post.location.longitude
            let latDelta = region.span.latitudeDelta * 1.2 // Add 20% padding
            let longDelta = region.span.longitudeDelta * 1.2
            
            let minLat = region.center.latitude - latDelta/2
            let maxLat = region.center.latitude + latDelta/2
            let minLong = region.center.longitude - longDelta/2
            let maxLong = region.center.longitude + longDelta/2
            
            return postLat >= minLat && postLat <= maxLat && 
                   postLong >= minLong && postLong <= maxLong
        }
        
        // Limit to 5 items for the stack
        return Array(visiblePosts.prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            mapContent
                .navigationTitle("explore.map_title".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    leadingToolbarItems
                    trailingToolbarItems
                }
                .navigationDestination(isPresented: $showPostDetail) {
                    if let post = selectedPost {
                        PostDetailView(post: post, categories: categories)
                    }
                }
        }
    }
    
    private var mapContent: some View {
        ZStack {
            mapView
            
            if selectedPost != nil {
                selectedPostCard
            } else if isZoomedInEnough && !visiblePosts.isEmpty {
                visiblePostsList
            }
        }
    }
    
    private var mapView: some View {
        Map(position: $mapPosition) {
            ForEach(posts) { post in
                let coordinate = CLLocationCoordinate2D(
                    latitude: post.location.latitude,
                    longitude: post.location.longitude
                )
                
                Annotation("",
                    coordinate: coordinate
                ) {
                    PostAnnotationView(
                        post: post,
                        isSelected: selectedPost?.id == post.id,
                        action: { selectedPost = post }
                    )
                }
            }
        }
        .onAppear {
            // Initialize the position to match the region
            mapPosition = .region(region)
        }
        .onMapCameraChange { context in
            // Update region from the map camera position for filtering posts
            region = context.region
        }
        .mapStyle(.standard(pointsOfInterest: [], showsTraffic: false))
    }
    
    private var selectedPostCard: some View {
        Group {
            if let post = selectedPost {
                PostDetailCardView(
                    post: post, 
                    categories: categories,
                    showDetail: $showPostDetail
                )
            }
        }
    }
    
    private var visiblePostsList: some View {
        VisiblePostsListView(
            posts: visiblePosts,
            categories: categories,
            onSelectPost: { selectedPost = $0 },
            isZoomedInEnough: isZoomedInEnough
        )
    }
    
    private var leadingToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("common.close".localized) {
                dismiss()
            }
        }
    }
    
    private var trailingToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                // Reset selection
                selectedPost = nil
            }) {
                Image(systemName: "arrow.counterclockwise")
            }
            .disabled(selectedPost == nil)
        }
    }
}

#Preview {
    MapView(posts: [], categories: [])
}
