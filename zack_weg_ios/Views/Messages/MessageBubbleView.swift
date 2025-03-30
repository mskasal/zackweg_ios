import SwiftUI
import Foundation

struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    let isLastInGroup: Bool
    let showTimestamp: Bool
    
    init(
        message: Message,
        isFromCurrentUser: Bool,
        isLastInGroup: Bool = true,
        showTimestamp: Bool = true
    ) {
        self.message = message
        self.isFromCurrentUser = isFromCurrentUser
        self.isLastInGroup = isLastInGroup
        self.showTimestamp = showTimestamp
    }
    
    var body: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
            HStack {
                if isFromCurrentUser {
                    Spacer()
                }
                
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                
                if !isFromCurrentUser {
                    Spacer()
                }
            }
            
            if showTimestamp || isLastInGroup {
                HStack {
                    if isFromCurrentUser {
                        Spacer()
                        
                        if message.isRead {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text(formatTime(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if !isFromCurrentUser {
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 2)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Preview code intentionally commented out due to missing Message initializer
// #Preview {
//     VStack {
//         MessageBubbleView(message: sampleMessage1, isFromCurrentUser: true, isLastInGroup: true, showTimestamp: true)
//         MessageBubbleView(message: sampleMessage2, isFromCurrentUser: false, isLastInGroup: true, showTimestamp: true)
//     }
//     .padding()
// }
//
// private extension MessageBubbleView {
//     static var sampleMessage1: Message = {
//         // Create a sample message for preview
//         let jsonData = """
//         {
//             "id": "1",
//             "conversation_id": "conv1",
//             "sender_id": "user1",
//             "content": "Hello, how are you?",
//             "created_at": "2023-05-10T10:30:00Z",
//             "is_read": true
//         }
//         """.data(using: .utf8)!
//         return try! JSONDecoder().decode(Message.self, from: jsonData)
//     }()
//     
//     static var sampleMessage2: Message = {
//         // Create a sample message for preview
//         let jsonData = """
//         {
//             "id": "2",
//             "conversation_id": "conv1",
//             "sender_id": "user2",
//             "content": "I'm good! How about you?",
//             "created_at": "2023-05-10T10:35:00Z",
//             "is_read": false
//         }
//         """.data(using: .utf8)!
//         return try! JSONDecoder().decode(Message.self, from: jsonData)
//     }()
// }
