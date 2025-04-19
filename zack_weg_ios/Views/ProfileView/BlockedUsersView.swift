//
//  BlockedUsersView.swift
//  zack_weg_ios
//
//  Created by Mustafa Samed Kasal on 25.03.25.
//

import SwiftUI

struct BlockedUsersView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var userToUnblock: PublicUser? = nil
    @State private var showingUnblockConfirmation = false
    
    var body: some View {
        List {
            if viewModel.isLoadingBlockedUsers {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if viewModel.blockedUsers.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding(.bottom, 4)
                        
                        Text("profile.no_blocked_users".localized)
                            .font(.headline)
                        
                        Text("profile.no_blocked_users_description".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.blockedUsers, id: \.id) { user in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // User info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.nickName)
                                    .font(.headline)
                                
                                // Find block details for this user
                                if let blockDetail = viewModel.blockDetails.first(where: { $0.blockedUserId == user.id }) {
                                    HStack(spacing: 8) {
                                        // Reason
                                        Text(blockDetail.reason.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        
                                        // Date - more prominently displayed
                                        Text(formatDate(blockDetail.createdAt))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Dedicated unblock button
                            Button(action: {
                                userToUnblock = user
                                showingUnblockConfirmation = true
                            }) {
                                Text("profile.unblock".localized)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("profile.blocked_users".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
        }
        
        .alert(isPresented: .init(
            get: { viewModel.blockedUsersError != nil },
            set: { if !$0 { viewModel.blockedUsersError = nil } }
        )) {
            Alert(
                title: Text("common.error".localized),
                message: Text(viewModel.blockedUsersError ?? ""),
                dismissButton: .default(Text("common.ok".localized))
            )
        }
        // Unblock confirmation alert
        .alert("profile.confirm_unblock_title".localized, isPresented: $showingUnblockConfirmation) {
            Button("common.cancel".localized, role: .cancel) {
                userToUnblock = nil
            }
            Button("profile.unblock".localized, role: .destructive) {
                if let user = userToUnblock {
                    Task {
                        await viewModel.unblockUser(userId: user.id)
                    }
                }
                userToUnblock = nil
            }
        } message: {
            if let user = userToUnblock {
                Text(String(format: "profile.confirm_unblock_message".localized, user.nickName))
            } else {
                Text("profile.confirm_unblock_generic".localized)
            }
        }
        .task {
            await viewModel.loadBlockedUsers()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        BlockedUsersView(viewModel: ProfileViewModel())
    }
} 
