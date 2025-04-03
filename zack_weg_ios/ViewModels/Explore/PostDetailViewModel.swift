import Foundation
import SwiftUI

class PostDetailViewModel: ObservableObject {
    private let post: Post?
    private let postId: String
    @Published var loadedPost: Post?
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
            return userId == post.user.id
        } else if let loadedPost = loadedPost {
            return userId == loadedPost.user.id
        }
        return false
    }
    
    func loadPostDetails() async {
        guard !isLoadingPost else {
            return
        }
        
        await MainActor.run {
            isLoadingPost = true
            error = nil
            // Clear the cached post to ensure we get fresh data
            loadedPost = nil
        }
        
        do {
            let fetchedPost = try await APIService.shared.getPostById(postId)
            await MainActor.run {
                self.loadedPost = fetchedPost
                print("Successfully loaded post details for ID: \(postId)")
            }
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
    
    func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func getInitials(for name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let firstInitial = components[0].prefix(1)
            let lastInitial = components[1].prefix(1)
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let firstChar = name.first {
            return String(firstChar).uppercased()
        }
        return "?"
    }
} 