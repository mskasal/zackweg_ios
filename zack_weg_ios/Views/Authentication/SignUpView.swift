import SwiftUI
import UIKit

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var nickName = ""
    @State private var postalCode = ""
    @State private var countryCode = "DEU"
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPassword = false
    @State private var shakeFieldIndex: Int? = nil
    
    private let countries = [
        ("DEU", "Germany")
    ]
    
    // Form validation
    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private var isPasswordValid: Bool {
        return password.count >= 8
    }
    
    private var isPostalCodeValid: Bool {
        return !postalCode.isEmpty
    }
    
    private var isCountryCodeValid: Bool {
        return countries.contains { $0.0 == countryCode }
    }
    
    private var isNickNameValid: Bool {
        return !nickName.isEmpty
    }
    
    private var isFormValid: Bool {
        return isEmailValid && isPasswordValid && isPostalCodeValid && isCountryCodeValid && isNickNameValid
    }
    
    // For password strength
    private var passwordStrength: Int {
        var strength = 0
        
        if password.count >= 8 {
            strength += 1
        }
        
        if password.rangeOfCharacter(from: .decimalDigits) != nil {
            strength += 1
        }
        
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil {
            strength += 1
        }
        
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()")) != nil {
            strength += 1
        }
        
        return strength
    }
    
    // Border color based on password strength
    private func getBorderColor(for password: String) -> Color {
        if password.isEmpty {
            return Color.clear
        }
        
        let strength = passwordStrength
        
        if strength == 0 {
            return Color.red.opacity(0.5)
        } else if strength < 3 {
            return Color.orange.opacity(0.7)
        } else {
            return Color.green.opacity(0.7)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Space for brand image
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 120, height: 120)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .overlay(
                        Image(systemName: "person.badge.plus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.blue)
                            .frame(width: 80, height: 80)
                            .accessibilityHidden(true)
                    )
                    .accessibilityIdentifier("signUpLogo")
                
                // Title section
                Text("auth.create_account".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("signUpCreateAccountText")
                
                Text("auth.create_account_subtitle".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 25)
                    .accessibilityIdentifier("signUpCreateAccountSubtitleText")
                
                // Form Fields
                VStack(spacing: 16) {
                    // Nickname
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("auth.signup.nickname.placeholder".localized, text: $nickName)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isNickNameValid || nickName.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .accessibilityLabel("auth.nickname".localized)
                            .accessibilityIdentifier("signUpNameTextField")
                        
                        if !isNickNameValid && !nickName.isEmpty {
                            Text("auth.nickname_required".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                                .accessibilityIdentifier("signUpNameValidationError")
                        }
                    }
                    
                    // Email
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("auth.signup.email.placeholder".localized, text: $email)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isEmailValid || email.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .accessibilityLabel("auth.email".localized)
                            .accessibilityIdentifier("signUpEmailTextField")
                        
                        if !isEmailValid && !email.isEmpty {
                            Text("auth.invalid_email".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                                .accessibilityIdentifier("signUpEmailValidationError")
                        }
                    }
                    
                    // Country and Postal Code
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            // Country (Germany)
                            HStack {
                                Text("🇩🇪")
                                    .font(.title3)
                                Text("auth.country_germany".localized)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .accessibilityLabel("Country: Germany")
                            .accessibilityIdentifier("signUpCountrySelector")
                            
                            // Postal Code
                            TextField("auth.signup.postal_code.placeholder".localized, text: $postalCode)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .keyboardType(.numberPad)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isPostalCodeValid || postalCode.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                                )
                                .accessibilityLabel("auth.postal_code".localized)
                                .accessibilityIdentifier("signUpPostalCodeTextField")
                        }
                        
                        if !isPostalCodeValid && !postalCode.isEmpty {
                            Text("auth.postal_code_required".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                                .accessibilityIdentifier("signUpPostalCodeValidationError")
                        }
                    }
                    
                    // Password field with visibility toggle and strength indicator
                    VStack(alignment: .leading, spacing: 4) {
                        ZStack(alignment: .trailing) {
                            if showPassword {
                                TextField("auth.signup.password.placeholder".localized, text: $password)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(10)
                                    .accessibilityLabel("auth.password".localized)
                                    .accessibilityIdentifier("signUpPasswordTextField")
                                    .onChange(of: password) { _ in
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            // Trigger animation of strength indicator
                                        }
                                    }
                            } else {
                                SecureField("auth.signup.password.placeholder".localized, text: $password)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(10)
                                    .accessibilityLabel("auth.password".localized)
                                    .accessibilityIdentifier("signUpPasswordTextField")
                                    .onChange(of: password) { _ in
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            // Trigger animation of strength indicator
                                        }
                                    }
                            }
                            
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("auth.signup.password.toggle".localized)
                            .accessibilityIdentifier("signUpTogglePasswordButton")
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(getBorderColor(for: password), lineWidth: 1)
                        )
                        
                        // Password strength indicators
                        if !password.isEmpty {
                            HStack {
                                // Password strength text
                                Text(getPasswordStrengthText())
                                    .font(.caption)
                                    .foregroundColor(getPasswordStrengthColor())
                                    .fontWeight(.medium)
                                    .padding(.top, 6)
                                    .padding(.leading, 4)
                                    .accessibilityIdentifier("signUpPasswordStrengthText")
                                
                                Spacer()
                            }
                            .accessibilityLabel("Password strength: \(getPasswordStrengthText())")
                        }
                        
                        if !isPasswordValid && !password.isEmpty {
                            Text("auth.invalid_password".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                                .accessibilityIdentifier("signUpPasswordValidationError")
                        }
                    }
                    
                    // Terms agreement
                    VStack(spacing: 4) {
                        TermsAgreementText()
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("signUpTermsAgreementSection")
                    
                    // Register button
                    Button(action: {
                        handleSignUp()
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        } else {
                            Text("auth.sign_up".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(isFormValid ? Color.blue : Color.blue.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(authViewModel.isLoading || !isFormValid)
                    .accessibilityLabel("auth.sign_up".localized)
                    .accessibilityIdentifier("signUpButton")
                    .padding(.top, 16)
                }
                .padding(.horizontal, 25)
            }
            .padding(.bottom, 30)
        }
        .accessibilityIdentifier("signUpScreenView")
        .alert(isPresented: $showError) {
            Alert(
                title: Text("common.error".localized),
                message: Text(errorMessage),
                dismissButton: .default(Text("common.ok".localized))
            )
        }
    }
    
    private func getPasswordStrengthText() -> String {
        switch passwordStrength {
        case 0:
            return "settings.password_weak".localized
        case 1, 2:
            return "settings.password_medium".localized
        case 3, 4:
            return "settings.password_strong".localized
        default:
            return ""
        }
    }
    
    private func getPasswordStrengthColor() -> Color {
        switch passwordStrength {
        case 0, 1:
            return Color.red
        case 2:
            return Color.orange
        case 3, 4:
            return Color.green
        default:
            return Color.gray
        }
    }
    
    private func handleSignUp() {
        if !isFormValid {
            if !isNickNameValid {
                errorMessage = "auth.nickname_missing_explanation".localized
                showError = true
                return
            }
            
            if !isEmailValid {
                errorMessage = "auth.invalid_email_explanation".localized
                showError = true
                return
            }
            
            if !isPostalCodeValid {
                errorMessage = "auth.postal_code_missing_explanation".localized
                showError = true
                return
            }
            
            if !isPasswordValid {
                errorMessage = "auth.invalid_password_explanation".localized
                showError = true
                return
            }
            
            return
        }
        
        Task {
            do {
                try await authViewModel.signUp(
                    email: email,
                    password: password,
                    postalCode: postalCode,
                    countryCode: countryCode,
                    nickName: nickName
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Helper Views

/// A separate component to handle the terms agreement text and links
private struct TermsAgreementText: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("auth.signup.agree_prefix".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize()
            
            Button {
                openTerms()
            } label: {
                Text(" \("auth.signup.terms".localized) ")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .underline()
            }.fixedSize()
            
            Text("auth.signup.and".localized)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button {
                openPrivacy()
            } label: {
                Text(" \("auth.signup.privacy".localized)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .underline()
            }.fixedSize()
        }
        .multilineTextAlignment(.leading)
    }
    
    // Open Terms of Service in browser
    private func openTerms() {
        if let url = URL(string: "https://zackweg.com/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    // Open Privacy Policy in browser
    private func openPrivacy() {
        if let url = URL(string: "https://zackweg.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SignUpView(authViewModel: AuthViewModel())
}
