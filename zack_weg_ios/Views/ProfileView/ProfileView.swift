//
//  ProfileView.swift
//  zack_weg_ios
//
//  Created by Mustafa Samed Kasal on 25.03.25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showSettings = false
    @State private var showBlockedUsers = false
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Compute the profile URL with the appropriate language code
    private var profileURL: URL {
        // Get user ID from the KeychainManager (fall back to UserDefaults if needed)
        let userId = KeychainManager.shared.getUserId() ?? 
                     UserDefaults.standard.string(forKey: "userId") ?? 
                     "user"
        
        // Use German ('de') for Turkish language since Turkish pages don't exist
        let languageCode = languageManager.currentLanguage == .turkish ? "de" : languageManager.currentLanguage.rawValue
        
        // Create the URL string and convert to URL (fallback to a default if URL creation fails)
        return URL(string: "https://www.zackweg.de/\(languageCode)/users/\(userId)") ?? 
               URL(string: "https://www.zackweg.de")!
    }
    
    var body: some View {
        List {
            // Header section with user info
            Section {
                HStack(spacing: 16) {
                    // Avatar placeholder
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Text(viewModel.getInitials())
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .accessibilityIdentifier("userAvatarView")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(UserDefaults.standard.string(forKey: "userNickName") ?? "User")
                            .font(.headline)
                            .accessibilityIdentifier("userNicknameText")
                        
                        Text(UserDefaults.standard.string(forKey: "userEmail") ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("userEmailText")
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .accessibilityIdentifier("userProfileHeader")
            }
            
            // My Posts section
            Section {
                NavigationLink(destination: UserPostsView(userId: UserDefaults.standard.string(forKey: "userId") ?? "")) {
                    HStack {
                        Label("posts.my_posts".localized, systemImage: "square.grid.2x2")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
                .accessibilityIdentifier("myPostsButton")
            } header: {
                Text("posts.title".localized)
            }
            
            // Blocked Users section
            Section {
                Button(action: {
                    showBlockedUsers = true
                }) {
                    HStack {
                        Label("profile.blocked_users".localized, systemImage: "person.crop.circle.badge.xmark")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .accessibilityIdentifier("blockedUsersButton")
            } header: {
                Text("profile.privacy".localized)
            }
        }
        .navigationTitle("profile.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    // Share button
                    ShareLink(
                        item: profileURL,
                        subject: Text("profile.share.subject".localized),
                        message: Text("profile.share.message".localized)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .accessibilityLabel("profile.share".localized)
                            .accessibilityIdentifier("shareProfileButton")
                    }
                    
                    // Settings button
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("settings.title".localized)
                            .accessibilityIdentifier("settingsButton")
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                SettingsView()
            }
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showBlockedUsers) {
            NavigationView {
                BlockedUsersView(viewModel: viewModel)
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            viewModel.loadProfileData()
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(LanguageManager.shared)
    }
} 
