import SwiftUI
import Foundation

struct PostCard: View {
    let post: Post
    @StateObject private var viewModel: PostCardViewModel
    @EnvironmentObject private var categoryViewModel: CategoryViewModel
    var userLocation: Location? = nil // Optional user location
    @State private var showingImagePreview = false
    @State private var loadedImages = false
    @Environment(\.colorScheme) private var colorScheme
    
    init(post: Post) {
        self.post = post
        // Proper initialization of StateObject using _viewModel
        _viewModel = StateObject(wrappedValue: PostCardViewModel(post: post))
    }
    
    private var category: Category? {
        categoryViewModel.getCategory(byId: post.categoryId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Gallery
            ZStack(alignment: .topLeading) {
                TabView {
                    if post.imageUrls.isEmpty {
                        // Placeholder when no images available
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    } else {
                        ForEach(post.imageUrls, id: \.self) { imageUrl in
                            optimizedAsyncImage(for: imageUrl)
                        }
                    }
                }
                .frame(height: 250)
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle())
                #endif
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Title and Price/Free badge
                HStack(alignment: .top) {
                    ZStack(alignment: .leading) {
                        NavigationLink(destination: PostDetailView(post: post)) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        Text(post.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    if post.offering == "SOLD_AT_PRICE" {
                        Text("€\(String(format: "%.2f", post.price!))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    } else if post.offering == "GIVING_AWAY" {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .font(.subheadline)
                            Text("common.free".localized)
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
                
                // Description - reduced to 2 lines
                Text(post.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Category only - removed status badge
                HStack(spacing: 8) {
                    if let category = category {
                        Text(category.title)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Location and Date info
                HStack {
                    // Show "Your Post" indicator when user is the owner, otherwise show poster's nickname
                    if viewModel.isOwner {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill.checkmark")
                                .font(.caption)
                                .foregroundColor(.green)
                                
                            Text("post_detail.your_post".localized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.08))
                        .cornerRadius(12)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                            Text(post.user.nickName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    // Location and time info side by side
                    HStack(spacing: 12) {
                        // Location with icon
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Show postal code with distance if user location is available
                            if let userLocation = userLocation {
                                let distance = calculateDistance(from: userLocation, to: post.location)
                                Text("\(post.location.postalCode) • \(formatDistance(distance))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(post.location.postalCode)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Time ago with icon
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(timeAgo(from: post.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .fullScreenCover(isPresented: $showingImagePreview) {
            PostCardImagePreviewView(imageUrls: post.imageUrls)
        }
        .environmentObject(categoryViewModel)
    }
    
    // Optimized image loading with caching and better placeholders
    private func optimizedAsyncImage(for imageUrlString: String) -> some View {
        AsyncImage(url: URL(string: imageUrlString), 
                   transaction: Transaction(animation: .easeInOut)) { phase in
            switch phase {
            case .empty:
                // Placeholder with shimmer effect
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                    )
                    .frame(height: 250)
                    .clipped()
                    .transition(.opacity)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipped()
                    .transition(.opacity)
                    .onTapGesture {
                        showingImagePreview = true
                    }
            case .failure:
                // Error placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
                    .frame(height: 250)
                    .clipped()
            @unknown default:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 250)
                    .clipped()
            }
        }
    }
    
    // Calculate distance between two locations
    private func calculateDistance(from location1: Location, to location2: Location) -> Double {
        let lat1 = location1.latitude
        let lon1 = location1.longitude
        let lat2 = location2.latitude
        let lon2 = location2.longitude
        
        // Haversine formula for calculating distance between two coordinates
        let theta = lon1 - lon2
        var dist = sin(deg2rad(lat1)) * sin(deg2rad(lat2)) + cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * cos(deg2rad(theta))
        dist = acos(dist)
        dist = rad2deg(dist)
        dist = dist * 60 * 1.1515 // Distance in miles
        
        // Convert to kilometers
        return dist * 1.609344
    }
    
    // Convert degrees to radians
    private func deg2rad(_ deg: Double) -> Double {
        return deg * .pi / 180.0
    }
    
    // Convert radians to degrees
    private func rad2deg(_ rad: Double) -> Double {
        return rad * 180.0 / .pi
    }
    
    // Format distance to be user-friendly
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1 {
            return "\(Int(distance * 1000))m"
        } else if distance < 10 {
            return String(format: "%.1fkm", distance)
        } else {
            return "\(Int(distance))km"
        }
    }
    
    // Human-readable time ago display
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfMonth], from: date, to: now)
        
        if let weeks = components.weekOfMonth, weeks > 0 {
            return weeks == 1 ? "time.week_ago".localized : String(format: "time.weeks_ago".localized, weeks)
        } else if let days = components.day, days > 0 {
            return days == 1 ? "time.yesterday".localized : String(format: "time.days_ago".localized, days)
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "time.hour_ago".localized : String(format: "time.hours_ago".localized, hours)
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "time.minute_ago".localized : String(format: "time.minutes_ago".localized, minutes)
        } else {
            return "time.just_now".localized
        }
    }
}

struct PostCardImagePreviewView: View {
    let imageUrls: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            TabView {
                ForEach(imageUrls, id: \.self) { imageUrl in
                    AsyncImage(url: URL(string: imageUrl), 
                               transaction: Transaction(animation: .easeInOut)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .transition(.opacity)
                        case .failure:
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            #if os(iOS)
            .tabViewStyle(PageTabViewStyle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
            #endif
        }
    }
} 
