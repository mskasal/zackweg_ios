import SwiftUI

struct UpdatePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
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
                        // Current password field with reveal button
                        ZStack(alignment: .trailing) {
                            if showCurrentPassword {
                                TextField("auth.current_password".localized, text: $currentPassword)
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("currentPasswordField")
                            } else {
                                SecureField("auth.current_password".localized, text: $currentPassword)
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("currentPasswordField")
                            }
                            
                            Button(action: {
                                showCurrentPassword.toggle()
                            }) {
                                Image(systemName: showCurrentPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("auth.toggle_password_visibility".localized)
                            .accessibilityIdentifier("toggleCurrentPasswordButton")
                            .padding(.trailing, 8)
                        }
                        
                        // New password field with reveal button
                        ZStack(alignment: .trailing) {
                            if showNewPassword {
                                TextField("auth.new_password".localized, text: $newPassword)
                                    .textContentType(.newPassword)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("newPasswordField")
                            } else {
                                SecureField("auth.new_password".localized, text: $newPassword)
                                    .textContentType(.newPassword)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("newPasswordField")
                            }
                            
                            Button(action: {
                                showNewPassword.toggle()
                            }) {
                                Image(systemName: showNewPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("auth.toggle_password_visibility".localized)
                            .accessibilityIdentifier("toggleNewPasswordButton")
                            .padding(.trailing, 8)
                        }
                        
                        // Password strength indicator
                        HStack {
                            Text(passwordStrength.text)
                                .font(.caption)
                                .foregroundColor(passwordStrength.color)
                                .accessibilityIdentifier("passwordStrengthLabel")
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                ForEach(0..<3) { index in
                                    Rectangle()
                                        .fill(strengthBarColor(for: index))
                                        .frame(width: 20, height: 4)
                                        .cornerRadius(2)
                                }
                            }
                            .accessibilityIdentifier("strengthBars")
                        }
                        .padding(.top, 4)
                        .accessibilityIdentifier("passwordStrengthIndicator")
                        
                        // Confirm password field with reveal button
                        ZStack(alignment: .trailing) {
                            if showConfirmPassword {
                                TextField("auth.confirm_password".localized, text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("confirmPasswordField")
                            } else {
                                SecureField("auth.confirm_password".localized, text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("confirmPasswordField")
                            }
                            
                            Button(action: {
                                showConfirmPassword.toggle()
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("auth.toggle_password_visibility".localized)
                            .accessibilityIdentifier("toggleConfirmPasswordButton")
                            .padding(.trailing, 8)
                        }
                        
                        if !confirmPassword.isEmpty && confirmPassword != newPassword {
                            Text("auth.password_mismatch".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                                .accessibilityIdentifier("passwordMismatchError")
                        }
                    }
                    .accessibilityIdentifier("passwordChangeSection")
                    
                    Section(header: Text("settings.requirements".localized), footer: Text("settings.password_requirements".localized)) {
                        PasswordRequirementRow(
                            text: "settings.req_min_chars".localized, 
                            isMet: newPassword.count >= 6
                        )
                        .accessibilityIdentifier("minCharsRequirement")
                        
                        PasswordRequirementRow(
                            text: "settings.req_uppercase".localized, 
                            isMet: newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil
                        )
                        .accessibilityIdentifier("uppercaseRequirement")
                        
                        PasswordRequirementRow(
                            text: "settings.req_lowercase".localized, 
                            isMet: newPassword.rangeOfCharacter(from: .lowercaseLetters) != nil
                        )
                        .accessibilityIdentifier("lowercaseRequirement")
                        
                        PasswordRequirementRow(
                            text: "settings.req_number".localized, 
                            isMet: newPassword.rangeOfCharacter(from: .decimalDigits) != nil
                        )
                        .accessibilityIdentifier("numberRequirement")
                        
                        PasswordRequirementRow(
                            text: "settings.req_special".localized, 
                            isMet: newPassword.rangeOfCharacter(from: .punctuationCharacters) != nil
                        )
                        .accessibilityIdentifier("specialCharRequirement")
                    }
                    .accessibilityIdentifier("passwordRequirementsSection")
                    
                    if let error = error {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .accessibilityIdentifier("passwordUpdateErrorText")
                        }
                        .accessibilityIdentifier("passwordUpdateErrorSection")
                    }
                }
                .accessibilityIdentifier("updatePasswordForm")
                
                if isLoading {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .accessibilityIdentifier("passwordUpdateProgressView")
                        )
                        .zIndex(2)
                        .accessibilityIdentifier("passwordUpdateLoadingOverlay")
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
                    .accessibilityIdentifier("cancelPasswordUpdateButton")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        Task {
                            await savePassword()
                        }
                    }
                    .disabled(!isValid || isLoading)
                    .opacity(isValid ? 1.0 : 0.5)
                    .accessibilityIdentifier("savePasswordButton")
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
            .accessibilityIdentifier("updatePasswordScreen")
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
        }
    }
}

#Preview {
    UpdatePasswordView()
} 
