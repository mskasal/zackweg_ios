import Foundation
import SwiftUI

class PostDetailViewModel: ObservableObject {
    private let post: Post
    @Published var seller: PublicUser?
    @Published var isLoadingSeller = false
    @Published var messageText = ""
    @Published var error: String?
    @Published var conversation: Conversation?
    
    init(post: Post) {
        self.post = post
        print("PostDetailViewModel initialized for post: \(post.id)")
    }
    
    var isOwner: Bool {
        UserDefaults.standard.string(forKey: "userId") == post.userId
    }
    
    func loadSellerInfo() async {
        // Guard against reloading if already loaded or in progress
        guard !isLoadingSeller && seller == nil else { 
            print("Seller info already loaded or in progress")
            return 
        }
        
        print("Loading seller info for post: \(post.id), seller ID: \(post.userId)")
        
        await MainActor.run {
            isLoadingSeller = true
        }
        
        do {
            let user = try await APIService.shared.getUserById(post.userId)
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
        
        print("Sending message to post: \(post.id), message: \(messageText)")
        
        do {
            let newConversation = try await APIService.shared.startConversation(
                postId: post.id,
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
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if let days = components.day, days > 0 {
            return days == 1 ? "Yesterday" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
} 