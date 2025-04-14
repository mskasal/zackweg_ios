import SwiftUI
import Foundation
import UIKit

struct PostCard: View {
    let post: Post
    @StateObject private var viewModel: PostCardViewModel
    @EnvironmentObject private var categoryViewModel: CategoryViewModel
    var userLocation: Location? = nil // Optional user location, will be removed in future
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
                        EmptyImagePlaceholderView(height: 250)
                    } else {
                        ForEach(post.imageUrls, id: \.self) { imageUrl in
                            OptimizedAsyncImageView(
                                imageUrl: imageUrl,
                                height: 250,
                                onTapAction: { showingImagePreview = true }
                            )
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
                        Text(String(post.price!).asPriceText())
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
                                .font(.caption)
                            Text("common.free".localized)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green)
                        .cornerRadius(6)
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
                            
                            // Only show postal code
                            Text(post.location.postalCode)
                                .font(.caption)
                                .foregroundColor(.secondary)
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
            PostImagePreviewView(imageUrls: post.imageUrls)
        }
        .environmentObject(categoryViewModel)
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

// No need for PostCardImagePreviewView as it's been moved to common components 
