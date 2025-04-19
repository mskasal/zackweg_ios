import SwiftUI
import UIKit

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Form validation
    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(of: emailRegex, options: .regularExpression) != nil
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
                        Image(systemName: "lock.shield")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.blue)
                            .frame(width: 80, height: 80)
                    )
                    .accessibilityIdentifier("forgotPasswordLogo")
                
                // Title section
                Text("auth.reset_password".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                    .accessibilityIdentifier("forgotPasswordTitleText")
                
                Text("auth.reset_instructions".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 25)
                    .padding(.bottom, 20)
                    .accessibilityIdentifier("forgotPasswordInstructionText")
                
                // Form section
                VStack(spacing: 12) {
                    // Email field
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("auth.signup.email.placeholder".localized, text: $email)
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
                            .accessibilityIdentifier("forgotPasswordEmailTextField")
                        
                        // Error message
                        if !isEmailValid && !email.isEmpty {
                            Text("auth.invalid_email".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                                .transition(.opacity)
                                .padding(.leading, 4)
                                .accessibilityIdentifier("forgotPasswordEmailValidationError")
                        }
                    }
                    
                    // Reset Button
                    Button(action: {
                        Task {
                            if !isEmailValid {
                                errorMessage = "auth.invalid_email".localized
                                showError = true
                                return
                            }
                            
                            do {
                                try await authViewModel.resetPassword(email: email)
                                showSuccess = true
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
                            Text("auth.reset_password".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(isEmailValid ? Color.blue : Color.blue.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(authViewModel.isLoading)
                    .padding(.top, 10)
                    .accessibilityIdentifier("resetPasswordButton")
                    
                    // Back to sign in button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("auth.sign_in".localized)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 16)
                    .accessibilityIdentifier("backToSignInButton")
                }
                .padding(.horizontal, 25)
                
                // Copyright text
                Text("© 2025 ZackWeg. All rights reserved.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                    .accessibilityIdentifier("forgotPasswordCopyrightText")
                
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .accessibilityIdentifier("forgotPasswordScreenView")
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
        .alert(isPresented: $showError) {
            Alert(
                title: Text("common.error".localized),
                message: Text(errorMessage),
                dismissButton: .default(Text("common.ok".localized))
            )
        }
        .alert("auth.email_sent".localized, isPresented: $showSuccess) {
            Button("common.ok".localized, role: .cancel) {
                dismiss()
            }
        } message: {
            Text("auth.check_email".localized)
        }
    }
}

#Preview {
    ForgotPasswordView(authViewModel: AuthViewModel())
} 
