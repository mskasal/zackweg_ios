import SwiftUI
import UIKit

struct SignInView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var showPassword = false
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Form validation
    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private var isPasswordValid: Bool {
        return password.count >= 8
    }
    
    private var isFormValid: Bool {
        return isEmailValid && isPasswordValid
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Language switcher
                HStack {
                    LanguageSwitcherView()
                    Spacer()
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)
                
                // Logo - different for dark/light mode
                if colorScheme == .dark {
                    Image("Logo-nobg")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                } else {
                    Image("Logo-no-bg-reverse-blue")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                }
                
                // Title section
                Text("auth.welcome_back".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                Text("auth.sign_in_to_account".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
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
                        ZStack(alignment: .trailing) {
                            if showPassword {
                                TextField("auth.signup.password.placeholder".localized, text: $password)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(10)
                            } else {
                                SecureField("auth.signup.password.placeholder".localized, text: $password)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(10)
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
                        }
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
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button(action: { showForgotPassword = true }) {
                            Text("auth.forgot_password".localized)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 2)
                    .padding(.bottom, 6)
                    
                    // Sign In Button
                    Button(action: {
                        Task {
                            if !isFormValid {
                                errorMessage = "auth.fix_form_errors".localized
                                showError = true
                                return
                            }
                            
                            do {
                                try await authViewModel.signIn(email: email, password: password)
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
                            Text("auth.sign_in".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(isFormValid ? Color.blue : Color.blue.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(authViewModel.isLoading)
                    
                    // Sign Up link
                    HStack {
                        Text("auth.no_account".localized)
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        Button(action: { showSignUp = true }) {
                            Text("auth.sign_up".localized)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 25)
                
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
        .sheet(isPresented: $showSignUp) {
            SignUpView(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(authViewModel: authViewModel)
        }
    }
}

#Preview {
    SignInView(authViewModel: AuthViewModel())
        .environmentObject(LanguageManager.shared)
    // Add the line below if testing in previews
    // .environment(\.locale, .init(identifier: "de"))
} 
