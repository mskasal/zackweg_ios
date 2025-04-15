//
//  BlockUserView.swift
//  zack_weg_ios
//
//  Created by Mustafa Samed Kasal on 25.03.25.
//

import SwiftUI

struct BlockUserView: View {
    @StateObject private var viewModel: BlockUserViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingBlockConfirmation = false
    
    init(userId: String, userName: String) {
        _viewModel = StateObject(wrappedValue: BlockUserViewModel(userId: userId, userName: userName))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Instructions only, removed title
                    Text(String(format: "profile.block_user_instructions".localized, viewModel.userName))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                    
                    // Reason selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("profile.block_reason_label".localized)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ForEach(BlockReason.allCases, id: \.self) { reason in
                            Button(action: {
                                viewModel.selectedReason = reason
                            }) {
                                HStack {
                                    Text(reason.displayName)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if viewModel.selectedReason == reason {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.selectedReason == reason ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                )
                            }
                        }
                    }
                    
                    if viewModel.selectedReason == .other {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("profile.additional_details".localized)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("profile.more_info_placeholder".localized, text: $viewModel.additionalComment)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                        }
                    }
                    
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            
            // Submit button area (fixed at bottom)
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    Button(action: {
                        showingBlockConfirmation = true
                    }) {
                        Text("profile.block_submit".localized)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
        }
        .navigationTitle("profile.block_user_title".localized)
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
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .alert(isPresented: $showingBlockConfirmation) {
            Alert(
                title: Text("profile.confirm_block_title".localized),
                message: Text(String(format: "profile.confirm_block_message".localized, viewModel.userName)),
                primaryButton: .destructive(Text("profile.block_submit".localized)) {
                    Task {
                        await viewModel.blockUser()
                        if viewModel.isSuccess {
                            dismiss()
                        }
                    }
                },
                secondaryButton: .cancel(Text("common.cancel".localized))
            )
        }
    }
}

#Preview {
    NavigationView {
        BlockUserView(userId: "user-123", userName: "JohnDoe")
    }
} 