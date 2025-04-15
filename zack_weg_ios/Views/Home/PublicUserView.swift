//
//  PublicUserView.swift
//  zack_weg_ios
//
//  Created by Mustafa Samed Kasal on 25.03.25.
//

import SwiftUI

struct PublicUserView: View {
    let userId: String
    let nickName: String
    @State private var showBlockUserView = false
    
    var body: some View {
        VStack(spacing: 0) {
            // User info header
            HStack(spacing: 16) {
                // Avatar placeholder
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text(getInitials())
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                // User name and ID
                VStack(alignment: .leading, spacing: 4) {
                    Text(nickName)
                        .font(.headline)
                    
                    Text(userId.prefix(8) + "...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Block user button
                Button(action: {
                    showBlockUserView = true
                }) {
                    Text("profile.block_user".localized)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Use the existing UserPostsView
            UserPostsView(
                userId: userId,
                userName: nickName,
                disablePostNavigation: false
            )
        }
        .navigationTitle(nickName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBlockUserView) {
            NavigationView {
                BlockUserView(userId: userId, userName: nickName)
            }
        }
    }
    
    private func getInitials() -> String {
        let components = nickName.components(separatedBy: " ")
        
        if components.count > 1, 
           let firstInitial = components[0].first,
           let lastInitial = components[1].first {
            return "\(firstInitial)\(lastInitial)"
        } else if let firstInitial = nickName.first {
            return String(firstInitial)
        }
        
        return "U"
    }
}

#Preview {
    PublicUserView(
        userId: "447eca21-81eb-4188-8214-8cfd546d6db1",
        nickName: "John Doe"
    )
} 