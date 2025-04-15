//
//  BlockUserViewModel.swift
//  zack_weg_ios
//
//  Created by Mustafa Samed Kasal on 25.03.25.
//

import Foundation

@MainActor
class BlockUserViewModel: ObservableObject {
    let userId: String
    let userName: String
    @Published var selectedReason: BlockReason = .inappropriateContent
    @Published var additionalComment = ""
    @Published var error: String?
    @Published var isLoading = false
    @Published var isSuccess = false
    
    private let apiService: APIService
    
    init(userId: String, userName: String, apiService: APIService = .shared) {
        self.userId = userId
        self.userName = userName
        self.apiService = apiService
    }
    
    func blockUser() async {
        isLoading = true
        error = nil
        
        do {
            try await apiService.blockUser(userId: userId, reason: selectedReason.rawValue)
            // In a production app, we might want to save the reason to our backend
            // This is where you'd make that call
            isSuccess = true
        } catch let error as APIError {
            switch error {
            case .badRequest(let message):
                self.error = message ?? "error.input.invalid".localized
            case .unauthorized:
                self.error = "error.auth.session_expired".localized
            case .serverError(let code, let message):
                self.error = message ?? String(format: "error.server.with_code".localized, code)
            default:
                self.error = error.localizedDescription
            }
            isSuccess = false
        } catch {
            self.error = error.localizedDescription
            isSuccess = false
        }
        
        isLoading = false
    }
} 