//
//  ProfileViewModel.swift
//  zack_weg_ios
//
//  Created by Mustafa Samed Kasal on 25.03.25.
//

import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let apiService: APIService
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var blockedUsers: [PublicUser] = []
    @Published var blockDetails: [BlockedUser] = []
    @Published var isLoadingBlockedUsers = false
    @Published var blockedUsersError: String?
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    func loadProfileData() {
        // Load profile data here
        isLoading = true
        
        // Simulating data loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
        }
    }
    
    func getInitials() -> String {
        let nickname = UserDefaults.standard.string(forKey: "userNickName") ?? "U"
        let components = nickname.components(separatedBy: " ")
        
        if components.count > 1, 
           let firstInitial = components[0].first,
           let lastInitial = components[1].first {
            return "\(firstInitial)\(lastInitial)"
        } else if let firstInitial = nickname.first {
            return String(firstInitial)
        }
        
        return "U"
    }
    
    @MainActor
    func loadBlockedUsers() async {
        isLoadingBlockedUsers = true
        blockedUsersError = nil
        
        do {
            blockedUsers = try await apiService.getBlockedUsers()
            
            // In a real implementation, you would get the blocked details separately or parse from response
            // For now, we'll mock some block details
            mockBlockDetails()
            
            print("✅ Loaded \(blockedUsers.count) blocked users")
        } catch let error as APIError {
            handleAPIError(error, for: "loadBlockedUsers")
        } catch {
            blockedUsersError = error.localizedDescription
            print("❌ Failed to load blocked users: \(error.localizedDescription)")
        }
        
        isLoadingBlockedUsers = false
    }
    
    // Mock function to create sample block details
    private func mockBlockDetails() {
        blockDetails = []
        
        // Create a mock block detail for each blocked user
        for user in blockedUsers {
            // Use a random reason
            let reasons: [BlockReason] = [.harassment, .spam, .inappropriateContent, .other]
            let randomReason = reasons.randomElement() ?? .other
            
            // Create a date sometime in the past
            let daysAgo = Int.random(in: 1...30)
            let blockedDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            
            // Create a block detail
            let blockDetail = try? JSONDecoder().decode(BlockedUser.self, from: """
            {
                "blocker_user_id": "\(UUID().uuidString)",
                "blocked_user_id": "\(user.id)",
                "reason": "\(randomReason.rawValue)",
                "created_at": "\(ISO8601DateFormatter().string(from: blockedDate))"
            }
            """.data(using: .utf8)!)
            
            if let blockDetail = blockDetail {
                blockDetails.append(blockDetail)
            }
        }
    }
    
    @MainActor
    func blockUser(userId: String) async {
        isLoadingBlockedUsers = true
        blockedUsersError = nil
        
        do {
            // Use "HARASSMENT" as default reason when blocking from profile view
            try await apiService.blockUser(userId: userId, reason: "HARASSMENT")
            // Refresh the blocked users list
            await loadBlockedUsers()
            print("✅ Successfully blocked user: \(userId)")
        } catch let error as APIError {
            handleAPIError(error, for: "blockUser")
        } catch {
            blockedUsersError = error.localizedDescription
            print("❌ Failed to block user: \(error.localizedDescription)")
        }
        
        isLoadingBlockedUsers = false
    }
    
    @MainActor
    func unblockUser(userId: String) async {
        isLoadingBlockedUsers = true
        blockedUsersError = nil
        
        do {
            try await apiService.unblockUser(userId: userId)
            // Remove the user from the blocked list if found
            blockedUsers.removeAll { $0.id == userId }
            blockDetails.removeAll { $0.blockedUserId == userId }
            print("✅ Successfully unblocked user: \(userId)")
        } catch let error as APIError {
            handleAPIError(error, for: "unblockUser")
        } catch {
            blockedUsersError = error.localizedDescription
            print("❌ Failed to unblock user: \(error.localizedDescription)")
        }
        
        isLoadingBlockedUsers = false
    }
    
    private func handleAPIError(_ error: APIError, for operation: String) {
        switch error {
        case .badRequest(let message):
            blockedUsersError = message ?? "error.input.invalid".localized
        case .unauthorized:
            blockedUsersError = "error.auth.session_expired".localized
        case .serverError(let code, let message):
            blockedUsersError = message ?? String(format: "error.server.with_code".localized, code)
        default:
            blockedUsersError = error.localizedDescription
        }
        print("❌ \(operation) failed: \(error.localizedDescription)")
    }
} 
