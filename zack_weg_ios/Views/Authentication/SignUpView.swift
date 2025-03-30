import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var nickName = ""
    @State private var postalCode = ""
    @State private var countryCode = "DEU"
    @State private var showError = false
    @State private var errorMessage = ""
    
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
    
    private var isConfirmPasswordValid: Bool {
        return password == confirmPassword && !confirmPassword.isEmpty
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
        return isEmailValid && isPasswordValid && isConfirmPasswordValid && 
               isPostalCodeValid && isCountryCodeValid && isNickNameValid
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Space for brand image
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 120, height: 120)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    .overlay(
                        Image(systemName: "person.badge.plus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.blue)
                            .frame(width: 80, height: 80)
                    )
                
                // Title section
                Text("auth.create_account".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                Text("auth.create_account_subtitle".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
                // Form section
                VStack(spacing: 12) {
                    // Email field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("auth.email".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $email)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isEmailValid || email.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                        
                        // Error message
                        if !isEmailValid && !email.isEmpty {
                            Text("auth.invalid_email".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                                .transition(.opacity)
                                .padding(.leading, 4)
                        }
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("auth.password".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("", text: $password)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isPasswordValid || password.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                        
                        // Error message
                        if !isPasswordValid && !password.isEmpty {
                            Text("auth.invalid_password".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                                .transition(.opacity)
                                .padding(.leading, 4)
                        }
                    }
                    
                    // Confirm Password field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("auth.confirm_password".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("", text: $confirmPassword)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isConfirmPasswordValid || confirmPassword.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                        
                        // Error message
                        if !isConfirmPasswordValid && !confirmPassword.isEmpty {
                            Text("auth.password_mismatch".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                                .transition(.opacity)
                                .padding(.leading, 4)
                        }
                    }
                    
                    // Postal Code field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("auth.postal_code".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $postalCode)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .keyboardType(.numberPad)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isPostalCodeValid || postalCode.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                        
                        // Error message
                        if !isPostalCodeValid && !postalCode.isEmpty {
                            Text("auth.postal_code_required".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                                .transition(.opacity)
                                .padding(.leading, 4)
                        }
                    }
                    
                    // Country (fixed to Germany)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("auth.country".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("auth.country_germany".localized)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    
                    // Nickname field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("auth.nickname".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $nickName)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isNickNameValid || nickName.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                        
                        // Error message
                        if !isNickNameValid && !nickName.isEmpty {
                            Text("auth.nickname_required".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                                .transition(.opacity)
                                .padding(.leading, 4)
                        }
                    }
                    
                    // Sign Up Button
                    Button(action: {
                        Task {
                            if !isFormValid {
                                errorMessage = "auth.fix_form_errors".localized
                                showError = true
                                return
                            }
                            
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
                                .background(isFormValid ? Color.blue : Color.blue.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(authViewModel.isLoading)
                    .padding(.top, 10)
                    
                    // Back to sign in
                    Button(action: {
                        dismiss()
                    }) {
                        Text("auth.already_have_account".localized) + Text(" ") + Text("auth.sign_in".localized)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 25).foregroundColor(.brandSecondary)
                
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("common.error".localized),
                message: Text(errorMessage),
                dismissButton: .default(Text("common.ok".localized))
            )
        }
    }
}

#Preview {
    SignUpView(authViewModel: AuthViewModel())
} 
