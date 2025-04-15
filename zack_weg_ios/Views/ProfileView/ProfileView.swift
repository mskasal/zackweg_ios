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
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .accessibilityLabel("settings.title".localized)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                SettingsView()
            }
        }
        .sheet(isPresented: $showBlockedUsers) {
            NavigationView {
                BlockedUsersView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadProfileData()
        }
    }
}

#Preview {
    ProfileView()
} 
