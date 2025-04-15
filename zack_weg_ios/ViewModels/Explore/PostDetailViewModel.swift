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
    @Published var showingImagePreview = false
    
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
        } catch let apiError as APIError {
            await MainActor.run {
                switch apiError {
                case .notFound:
                    self.error = "messages.post_not_available".localized
                case .serverError(let code, let message):
                    self.error = message ?? String(format: "error.server.with_code".localized, code)
                case .unauthorized:
                    self.error = "auth.sign_in_to_view".localized
                default:
                    self.error = apiError.localizedDescription
                }
                print("Error loading post: \(apiError.localizedDescription)")
            }
        } catch {
            await MainActor.run {
                self.error = String(format: "error.data.not_found".localized)
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
        } catch let apiError as APIError {
            await MainActor.run {
                switch apiError {
                case .notFound:
                    self.error = "messages.post_not_available".localized
                case .unauthorized:
                    self.error = "error.auth.unauthorized".localized
                case .permissionDenied:
                    self.error = "error.user.blocked".localized
                case .badRequest(let message):
                    self.error = message ?? "error.input.invalid".localized
                case .serverError(let code, let message):
                    self.error = message ?? String(format: "error.server.with_code".localized, code)
                default:
                    self.error = apiError.localizedDescription
                }
                print("Error sending message: \(apiError.localizedDescription)")
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
        } catch let apiError as APIError {
            await MainActor.run {
                switch apiError {
                case .notFound:
                    // The post is already gone, so mark as deleted
                    self.postDeleted = true
                    print("Post already deleted: \(postId)")
                case .unauthorized:
                    self.error = "error.permission.denied".localized
                case .serverError(let code, let message):
                    self.error = message ?? String(format: "error.server.with_code".localized, code)
                default:
                    self.error = String(format: "error.operation.failed".localized, apiError.localizedDescription)
                }
                print("Error deleting post: \(apiError.localizedDescription)")
            }
        } catch {
            await MainActor.run {
                self.error = String(format: "error.operation.failed".localized, error.localizedDescription)
                print("Error deleting post: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            isDeleting = false
        }
    }
    
    func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear], from: date, to: now)
        
        if let week = components.weekOfYear, week > 0 {
            return week == 1 ? "time.week_ago".localized : String(format: "time.weeks_ago".localized, week)
        }
        
        if let day = components.day, day > 0 {
            return day == 1 ? "time.yesterday".localized : String(format: "time.days_ago".localized, day)
        }
        
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "time.hour_ago".localized : String(format: "time.hours_ago".localized, hour)
        }
        
        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "time.minute_ago".localized : String(format: "time.minutes_ago".localized, minute)
        }
        
        return "time.just_now".localized
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