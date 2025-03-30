import SwiftUI

struct UpdatePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var error: String?
    
    private enum PasswordStrength {
        case empty, weak, medium, strong
        
        var color: Color {
            switch self {
            case .empty: return .gray
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }
        
        var text: String {
            switch self {
            case .empty: return "settings.password_empty".localized
            case .weak: return "settings.password_weak".localized
            case .medium: return "settings.password_medium".localized
            case .strong: return "settings.password_strong".localized
            }
        }
    }
    
    private var passwordStrength: PasswordStrength {
        if newPassword.isEmpty {
            return .empty
        }
        
        let hasUppercase = newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = newPassword.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasDigit = newPassword.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = newPassword.rangeOfCharacter(from: .punctuationCharacters) != nil
        
        let score = [hasUppercase, hasLowercase, hasDigit, hasSpecial].filter { $0 }.count
        
        if newPassword.count < 6 {
            return .weak
        } else if score <= 2 {
            return .weak
        } else if score == 3 {
            return .medium
        } else {
            return .strong
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("settings.change_password".localized)) {
                        SecureField("auth.current_password".localized, text: $currentPassword)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                        
                        SecureField("auth.new_password".localized, text: $newPassword)
                            .textContentType(.newPassword)
                            .autocorrectionDisabled()
                        
                        // Password strength indicator
                        HStack {
                            Text(passwordStrength.text)
                                .font(.caption)
                                .foregroundColor(passwordStrength.color)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                ForEach(0..<3) { index in
                                    Rectangle()
                                        .fill(strengthBarColor(for: index))
                                        .frame(width: 20, height: 4)
                                        .cornerRadius(2)
                                }
                            }
                        }
                        .padding(.top, 4)
                        
                        SecureField("auth.confirm_password".localized, text: $confirmPassword)
                            .textContentType(.newPassword)
                            .autocorrectionDisabled()
                        
                        if !confirmPassword.isEmpty && confirmPassword != newPassword {
                            Text("auth.password_mismatch".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    
                    Section(header: Text("settings.requirements".localized), footer: Text("settings.password_requirements".localized)) {
                        PasswordRequirementRow(
                            text: "settings.req_min_chars".localized, 
                            isMet: newPassword.count >= 6
                        )
                        
                        PasswordRequirementRow(
                            text: "settings.req_uppercase".localized, 
                            isMet: newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil
                        )
                        
                        PasswordRequirementRow(
                            text: "settings.req_lowercase".localized, 
                            isMet: newPassword.rangeOfCharacter(from: .lowercaseLetters) != nil
                        )
                        
                        PasswordRequirementRow(
                            text: "settings.req_number".localized, 
                            isMet: newPassword.rangeOfCharacter(from: .decimalDigits) != nil
                        )
                        
                        PasswordRequirementRow(
                            text: "settings.req_special".localized, 
                            isMet: newPassword.rangeOfCharacter(from: .punctuationCharacters) != nil
                        )
                    }
                    
                    if let error = error {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                if isLoading {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        )
                        .zIndex(2)
                }
            }
            .navigationTitle("settings.update_password".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        Task {
                            await savePassword()
                        }
                    }
                    .disabled(!isValid || isLoading)
                    .opacity(isValid ? 1.0 : 0.5)
                }
            }
            .onChange(of: newPassword) { _ in
                error = nil
                showSuccess = false
            }
            .onChange(of: currentPassword) { _ in
                error = nil
                showSuccess = false
            }
            .onChange(of: confirmPassword) { _ in
                error = nil
                showSuccess = false
            }
            .alert("settings.password_updated".localized, isPresented: $showSuccess) {
                Button("common.ok".localized, role: .cancel) {}
            } message: {
                Text("settings.password_update_success".localized)
            }
        }
    }
    
    private var isValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 6
    }
    
    private func strengthBarColor(for index: Int) -> Color {
        switch passwordStrength {
        case .empty:
            return Color.gray.opacity(0.2)
        case .weak:
            return index == 0 ? .red : Color.gray.opacity(0.2)
        case .medium:
            return index <= 1 ? .orange : Color.gray.opacity(0.2)
        case .strong:
            return .green
        }
    }
    
    private func savePassword() async {
        guard newPassword == confirmPassword else {
            error = "auth.password_mismatch".localized
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            try await viewModel.updatePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            // Show success message
            isLoading = false
            showSuccess = true
            
            // Dismiss after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }
}

struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .primary : .secondary)
            Spacer()
        }
    }
}

#Preview {
    UpdatePasswordView()
} 