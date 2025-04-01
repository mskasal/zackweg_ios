import Foundation
import SwiftUI

class PostDetailViewModel: ObservableObject {
    private let post: Post?
    private let postId: String
    @Published var loadedPost: Post?
    @Published var seller: PublicUser?
    @Published var isLoadingSeller = false
    @Published var isLoadingPost = false
    @Published var messageText = ""
    @Published var error: String?
    @Published var conversation: Conversation?
    @Published var isDeleting = false
    @Published var postDeleted = false
    
    init(post: Post) {
        self.post = post
        self.postId = post.id
        self.loadedPost = post
        print("PostDetailViewModel initialized for post: \(post.id)")
    }
    
    init(postId: String) {
        self.post = nil
        self.postId = postId
        print("PostDetailViewModel initialized with postId: \(postId)")
    }
    
    var isOwner: Bool {
        let userId = UserDefaults.standard.string(forKey: "userId")
        if let post = post {
            return userId == post.userId
        } else if let loadedPost = loadedPost {
            return userId == loadedPost.userId
        }
        return false
    }
    
    func loadPostDetails() async {
        guard loadedPost == nil, !isLoadingPost else {
            return
        }
        
        await MainActor.run {
            isLoadingPost = true
            error = nil
        }
        
        do {
            let fetchedPost = try await APIService.shared.getPostById(postId)
            await MainActor.run {
                self.loadedPost = fetchedPost
                print("Successfully loaded post details for ID: \(postId)")
            }
            // Load seller info after post is loaded
            await loadSellerInfo()
        } catch {
            await MainActor.run {
                self.error = "Failed to load post: \(error.localizedDescription)"
                print("Error loading post: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            isLoadingPost = false
        }
    }
    
    func loadSellerInfo() async {
        // Guard against reloading if already loaded or in progress
        guard !isLoadingSeller && seller == nil else { 
            print("Seller info already loaded or in progress")
            return 
        }
        
        let userId = (post?.userId ?? loadedPost?.userId)
        guard let userId = userId else {
            print("Cannot load seller: No post data available")
            return
        }
        
        print("Loading seller info for post: \(postId), seller ID: \(userId)")
        
        await MainActor.run {
            isLoadingSeller = true
        }
        
        do {
            let user = try await APIService.shared.getUserById(userId)
            print("DEBUG: Received user data")
            print("DEBUG: User nickname: \(user.nickName)")
            
            await MainActor.run {
                self.seller = user
                print("Successfully loaded seller info: \(user.nickName)")
                print("DEBUG: Seller in ViewModel: Present")
            }
        } catch {
            print("Failed to load seller information: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            isLoadingSeller = false
        }
    }
    
    func sendMessage() async {
        guard !messageText.isEmpty else {
            print("Cannot send empty message")
            return
        }
        
        print("Sending message to post: \(postId), message: \(messageText)")
        
        do {
            let newConversation = try await APIService.shared.startConversation(
                postId: postId,
                message: messageText
            )
            
            await MainActor.run {
                conversation = newConversation
                print("Successfully started conversation with ID: \(newConversation.id)")
                messageText = "" // Clear the message text after sending
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    func getInitials(for name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1, 
           let firstInitial = components[0].first,
           let lastInitial = components[1].first {
            return "\(firstInitial)\(lastInitial)"
        } else if let firstInitial = components[0].first {
            return String(firstInitial)
        }
        return "?"
    }
    
    // Human-readable time ago display
    func timeAgo(from date: Date) -> String {
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
    
    func deletePost() async {
        guard isOwner else {
            print("Cannot delete post: User is not the owner")
            return
        }
        
        await MainActor.run {
            isDeleting = true
            error = nil
        }
        
        do {
            try await APIService.shared.deletePost(postId: postId)
            
            await MainActor.run {
                postDeleted = true
                print("Successfully deleted post with ID: \(postId)")
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to delete post: \(error.localizedDescription)"
                print("Error deleting post: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            isDeleting = false
        }
    }
} 