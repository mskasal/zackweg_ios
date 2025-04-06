import SwiftUI
import UIKit

// Field focus enum to track which field is currently focused
enum SignInField: Hashable {
    case email, password
}

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
    
    // Focus state to manage keyboard navigation
    @FocusState private var focusedField: SignInField?
    
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
    
    // Move to next field
    private func moveToNextField() {
        switch focusedField {
        case .email:
            focusedField = .password
        case .password:
            focusedField = nil // Done with form
            // Could also trigger sign in here
        case nil:
            break
        }
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
                        .accessibilityIdentifier("appLogo")
                } else {
                    Image("Logo-no-bg-reverse-blue")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                        .accessibilityIdentifier("appLogo")
                }
                
                // Title section
                Text("auth.welcome_back".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                    .accessibilityIdentifier("welcomeBackText")
                
                Text("auth.sign_in_to_account".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                    .accessibilityIdentifier("signInToAccountText")
                
                // Form section
                VStack(spacing: 12) {
                    // Email field
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("auth.email".localized, text: $email)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .textContentType(.emailAddress)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit(moveToNextField)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isEmailValid || email.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .accessibilityIdentifier("emailTextField")
                        
                        // Error message
                        if !isEmailValid && !email.isEmpty {
                            Text("auth.invalid_email".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                                .transition(.opacity)
                                .padding(.leading, 4)
                                .accessibilityIdentifier("emailValidationError")
                        }
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 4) {
                        ZStack(alignment: .trailing) {
                            if showPassword {
                                TextField("auth.password".localized, text: $password)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(10)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        handleSignIn()
                                    }
                                    .accessibilityIdentifier("passwordTextField")
                            } else {
                                SecureField("auth.password".localized, text: $password)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(10)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        handleSignIn()
                                    }
                                    .accessibilityIdentifier("passwordTextField")
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
                            .accessibilityIdentifier("togglePasswordButton")
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
                                .accessibilityIdentifier("passwordValidationError")
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
                        .accessibilityIdentifier("forgotPasswordButton")
                    }
                    .padding(.top, 2)
                    .padding(.bottom, 6)
                    
                    // Sign In Button
                    Button(action: handleSignIn) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .accessibilityIdentifier("signInProgressView")
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
                    .accessibilityIdentifier("signInButton")
                    .disabled(authViewModel.isLoading)
                    
                    // Sign Up link
                    HStack {
                        Text("auth.no_account".localized)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("noAccountText")
                        
                        Button(action: { showSignUp = true }) {
                            Text("auth.sign_up".localized)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .accessibilityIdentifier("createAccountButton")
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 25)
                
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                // Add keyboard navigation buttons
                Button(action: {
                    focusedField = nil
                }) {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                
                Spacer()
                
                if focusedField == .email {
                    Button(action: {
                        moveToNextField()
                    }) {
                        Text("Next")
                    }
                } else if focusedField == .password {
                    Button(action: {
                        handleSignIn()
                    }) {
                        Text("Sign In")
                    }
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
        .sheet(isPresented: $showSignUp) {
            SignUpView(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(authViewModel: authViewModel)
        }
        .accessibilityIdentifier("signInScreenView")
    }
    
    private func handleSignIn() {
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
    }
}

#Preview {
    SignInView(authViewModel: AuthViewModel())
        .environmentObject(LanguageManager.shared)
    // Add the line below if testing in previews
    // .environment(\.locale, .init(identifier: "de"))
} 
