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
    @State private var currentStep = 0
    @State private var termsAccepted = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var shakeFieldIndex: Int? = nil
    @State private var fieldInFocus: String? = nil
    
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
    
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0: // Account info
            return isEmailValid && isPasswordValid && isConfirmPasswordValid
        case 1: // Location
            return isPostalCodeValid && isCountryCodeValid
        case 2: // Profile
            return isNickNameValid
        case 3: // Terms & Conditions
            return termsAccepted
        default:
            return false
        }
    }
    
    private var isFormValid: Bool {
        return isEmailValid && isPasswordValid && isConfirmPasswordValid && 
               isPostalCodeValid && isCountryCodeValid && isNickNameValid && termsAccepted
    }
    
    // Computed properties for step titles
    private var stepTitle: String {
        switch currentStep {
        case 0:
            return "auth.account_info".localized
        case 1:
            return "auth.your_location".localized
        case 2:
            return "auth.your_profile".localized
        case 3:
            return "auth.terms_and_privacy".localized
        default:
            return ""
        }
    }
    
    private var stepSubtitle: String {
        switch currentStep {
        case 0:
            return "auth.account_info_subtitle".localized
        case 1:
            return "auth.location_subtitle".localized
        case 2:
            return "auth.profile_subtitle".localized
        case 3:
            return "auth.terms_subtitle".localized
        default:
            return ""
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Progress indicators
                HStack(spacing: 4) {
                    ForEach(0..<4) { step in
                        Capsule()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(step+1) of 4")
                            .accessibilityValue(step <= currentStep ? "completed" : "not completed")
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)
                
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
                
                // Title section
                Text(stepTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                    .accessibilityAddTraits(.isHeader)
                
                Text(stepSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 25)
                
                // Form section
                VStack(spacing: 12) {
                    // Step content
                    switch currentStep {
                    case 0:
                        accountInfoStep
                    case 1:
                        locationStep
                    case 2:
                        profileStep
                    case 3:
                        termsStep
                    default:
                        EmptyView()
                    }
                    
                    // Navigation buttons
                    HStack {
                        if currentStep > 0 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep -= 1
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("common.back".localized)
                                }
                                .padding()
                                .foregroundColor(.blue)
                            }
                            .accessibilityLabel("common.back".localized)
                        }
                        
                        Spacer()
                        
                        if currentStep < 3 {
                            Button(action: {
                                validateAndProceed()
                            }) {
                                HStack {
                                    Text("common.next".localized)
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .foregroundColor(isCurrentStepValid ? .white : .gray)
                                .background(isCurrentStepValid ? Color.blue : Color.blue.opacity(0.3))
                                .cornerRadius(10)
                            }
                            .disabled(!isCurrentStepValid)
                            .accessibilityLabel("common.next".localized)
                            .accessibilityHint(isCurrentStepValid ? "Tap to continue to next step" : "Please complete this step before continuing")
                        } else {
                            // Sign Up Button on the last step
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
                                        .background(isCurrentStepValid ? Color.blue : Color.blue.opacity(0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .disabled(authViewModel.isLoading || !isCurrentStepValid)
                            .accessibilityLabel("auth.sign_up".localized)
                            .accessibilityHint(isCurrentStepValid ? "Tap to create your account" : "Please accept terms and conditions")
                        }
                    }
                    .padding(.top, 16)
                    
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
                    .accessibilityLabel("auth.already_have_account".localized + " " + "auth.sign_in".localized)
                }
                .padding(.horizontal, 25)
                
                Spacer()
            }
            .padding(.bottom, 30)
            .onChange(of: fieldInFocus) { _ in
                // Logic for field focus changes could be implemented here
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("common.error".localized),
                message: Text(errorMessage),
                primaryButton: .default(Text("common.fix".localized)) {
                    // Move focus to the problematic field
                    focusProblemField()
                },
                secondaryButton: .cancel(Text("common.dismiss".localized))
            )
        }
    }
    
    // MARK: - Step Content Views
    
    private var accountInfoStep: some View {
        VStack(spacing: 18) {
            // Email field
            formField(
                title: "auth.email".localized,
                value: $email,
                isValid: isEmailValid || email.isEmpty,
                errorMessage: "auth.invalid_email".localized,
                keyboardType: .emailAddress,
                autocapitalization: .never,
                autocorrection: false,
                fieldId: "email"
            )
            
            // Password field with strength indicator
            VStack(alignment: .leading, spacing: 4) {
                Text("auth.password".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    if showPassword {
                        TextField("", text: $password)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isPasswordValid || password.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .accessibilityLabel("auth.password".localized)
                    } else {
                        SecureField("", text: $password)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isPasswordValid || password.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .accessibilityLabel("auth.password".localized)
                    }
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                    }
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }
                
                // Password strength indicator
                if !password.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Strength bar
                        HStack(spacing: 4) {
                            ForEach(1...4, id: \.self) { index in
                                Rectangle()
                                    .fill(passwordStrength >= index ? 
                                          (passwordStrength < 3 ? Color.orange : Color.green) :
                                          Color.gray.opacity(0.3))
                                    .frame(height: 4)
                            }
                        }
                        
                        // Requirements checklist
                        VStack(alignment: .leading, spacing: 4) {
                            requirementText("8+ characters", password.count >= 8)
                            requirementText("Contains numbers", password.rangeOfCharacter(from: .decimalDigits) != nil)
                            requirementText("Contains special characters", password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()")) != nil)
                        }
                        .font(.caption)
                    }
                }
                
                // Error message
                if !isPasswordValid && !password.isEmpty {
                    Text("auth.invalid_password".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                        .transition(.opacity)
                        .padding(.leading, 4)
                        .shakeEffect(trigger: shakeFieldIndex == 1)
                        .accessibilityLabel("Error: Password must be at least 8 characters")
                }
            }
            
            // Confirm Password field
            VStack(alignment: .leading, spacing: 4) {
                Text("auth.confirm_password".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    if showConfirmPassword {
                        TextField("", text: $confirmPassword)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isConfirmPasswordValid || confirmPassword.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .accessibilityLabel("auth.confirm_password".localized)
                    } else {
                        SecureField("", text: $confirmPassword)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isConfirmPasswordValid || confirmPassword.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .accessibilityLabel("auth.confirm_password".localized)
                    }
                    
                    Button(action: {
                        showConfirmPassword.toggle()
                    }) {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                    }
                    .accessibilityLabel(showConfirmPassword ? "Hide password" : "Show password")
                }
                
                // Error message
                if !isConfirmPasswordValid && !confirmPassword.isEmpty {
                    Text("auth.password_mismatch".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                        .transition(.opacity)
                        .padding(.leading, 4)
                        .shakeEffect(trigger: shakeFieldIndex == 2)
                        .accessibilityLabel("Error: Passwords do not match")
                }
            }
        }
    }
    
    private var locationStep: some View {
        VStack(spacing: 18) {
            // Postal Code field with tooltip
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("auth.postal_code".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        // Show postal code tooltip
                        errorMessage = "auth.postal_code_help".localized
                        showError = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Information about postal code")
                }
                
                TextField("", text: $postalCode)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .keyboardType(.numberPad)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isPostalCodeValid || postalCode.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                    )
                    .shakeEffect(trigger: shakeFieldIndex == 3)
                    .accessibilityLabel("auth.postal_code".localized)
                
                // Helper text
                Text("Example: 10115 (Berlin)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                // Error message
                if !isPostalCodeValid && !postalCode.isEmpty {
                    Text("auth.postal_code_required".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                        .transition(.opacity)
                        .padding(.leading, 4)
                        .accessibilityLabel("Error: Postal code is required")
                }
            }
            
            // Country (fixed to Germany)
            VStack(alignment: .leading, spacing: 4) {
                Text("auth.country".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    HStack {
                        Text("🇩🇪")
                            .font(.title3)
                        Text("auth.country_germany".localized)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .accessibilityLabel("Country: Germany")
                .accessibilityHint("Currently only available in Germany")
            }
            
            // Location explanation
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("auth.location_use_title".localized)
                        .font(.callout)
                        .fontWeight(.medium)
                    
                    Text("auth.location_use_explanation".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .accessibilityElement(children: .combine)
        }
    }
    
    private var profileStep: some View {
        VStack(spacing: 18) {
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
                    .shakeEffect(trigger: shakeFieldIndex == 4)
                    .accessibilityLabel("auth.nickname".localized)
                
                // Helper text
                Text("auth.nickname_help".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                // Error message
                if !isNickNameValid && !nickName.isEmpty {
                    Text("auth.nickname_required".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                        .transition(.opacity)
                        .padding(.leading, 4)
                        .accessibilityLabel("Error: Nickname is required")
                }
            }
            
            // Profile explanation
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("auth.profile_use_title".localized)
                        .font(.callout)
                        .fontWeight(.medium)
                    
                    Text("auth.profile_use_explanation".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .accessibilityElement(children: .combine)
        }
    }
    
    private var termsStep: some View {
        VStack(spacing: 20) {
            // Terms and Privacy Policy explanation
            VStack(alignment: .leading, spacing: 16) {
                // Privacy policy content
                VStack(alignment: .leading, spacing: 12) {
                    Text("auth.privacy_policy_title".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("auth.privacy_policy_summary".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button("auth.read_privacy_policy".localized) {
                        // Open privacy policy link
                    }
                    .font(.callout)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                    .accessibilityLabel("auth.read_privacy_policy".localized)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Terms of service content
                VStack(alignment: .leading, spacing: 12) {
                    Text("auth.terms_title".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("auth.terms_summary".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button("auth.read_terms".localized) {
                        // Open terms link
                    }
                    .font(.callout)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                    .accessibilityLabel("auth.read_terms".localized)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Terms acceptance
            HStack(alignment: .top, spacing: 10) {
                Button(action: {
                    termsAccepted.toggle()
                }) {
                    Image(systemName: termsAccepted ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundColor(termsAccepted ? .blue : .secondary)
                }
                .accessibilityLabel(termsAccepted ? "Accepted" : "Not accepted")
                .accessibilityHint("Double tap to \(termsAccepted ? "unaccept" : "accept") terms and privacy policy")
                
                Text("auth.terms_acceptance".localized)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(termsAccepted ? .primary : .secondary)
            }
            .padding()
            .background(termsAccepted ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(termsAccepted ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .animation(.easeInOut, value: termsAccepted)
            .shakeEffect(trigger: shakeFieldIndex == 5)
            .accessibilityElement(children: .combine)
        }
    }
    
    // MARK: - Helper Views
    
    private func formField(
        title: String,
        value: Binding<String>,
        isValid: Bool,
        errorMessage: String,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences,
        autocorrection: Bool = true,
        fieldId: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("", text: value)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .disableAutocorrection(!autocorrection)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
                )
                .shakeEffect(trigger: fieldId == getShakeFieldId())
                .accessibilityLabel(title)
            
            // Error message
            if !isValid {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                    .transition(.opacity)
                    .padding(.leading, 4)
                    .accessibilityLabel("Error: \(errorMessage)")
            }
        }
    }
    
    private func requirementText(_ text: String, _ isMet: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isMet ? .green : .gray)
            
            Text(text)
                .foregroundColor(isMet ? .primary : .secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text): \(isMet ? "met" : "not met")")
    }
    
    // MARK: - Helper Methods
    
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
    
    private func getShakeFieldId() -> String {
        switch shakeFieldIndex {
        case 0: return "email"
        case 1: return "password"
        case 2: return "confirmPassword"
        default: return ""
        }
    }
    
    private func validateAndProceed() {
        // Validate current step
        switch currentStep {
        case 0:
            if !isEmailValid {
                shakeField(0)
                errorMessage = "auth.invalid_email_explanation".localized
                showError = true
                return
            }
            if !isPasswordValid {
                shakeField(1)
                errorMessage = "auth.invalid_password_explanation".localized
                showError = true
                return
            }
            if !isConfirmPasswordValid {
                shakeField(2)
                errorMessage = "auth.password_mismatch_explanation".localized
                showError = true
                return
            }
        case 1:
            if !isPostalCodeValid {
                shakeField(3)
                errorMessage = "auth.postal_code_missing_explanation".localized
                showError = true
                return
            }
        case 2:
            if !isNickNameValid {
                shakeField(4)
                errorMessage = "auth.nickname_missing_explanation".localized
                showError = true
                return
            }
        default:
            break
        }
        
        // Proceed to next step
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }
    
    private func handleSignUp() {
        if !termsAccepted {
            shakeField(5)
            errorMessage = "auth.terms_acceptance_required".localized
            showError = true
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
                
                // Determine which step to go back to based on the error
                if error.localizedDescription.contains("email") {
                    withAnimation { currentStep = 0 }
                } else if error.localizedDescription.contains("postal") {
                    withAnimation { currentStep = 1 }
                } else if error.localizedDescription.contains("nick") {
                    withAnimation { currentStep = 2 }
                }
            }
        }
    }
    
    private func shakeField(_ index: Int) {
        withAnimation(.default) {
            shakeFieldIndex = index
            
            // Reset after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                shakeFieldIndex = nil
            }
        }
    }
    
    private func focusProblemField() {
        // Determine which step contains the error
        switch errorMessage {
        case let msg where msg.contains("email"):
            withAnimation { currentStep = 0 }
            shakeField(0)
        case let msg where msg.contains("password"):
            withAnimation { currentStep = 0 }
            if msg.contains("match") {
                shakeField(2)
            } else {
                shakeField(1)
            }
        case let msg where msg.contains("postal"):
            withAnimation { currentStep = 1 }
            shakeField(3)
        case let msg where msg.contains("nickname") || msg.contains("nick"):
            withAnimation { currentStep = 2 }
            shakeField(4)
        case let msg where msg.contains("terms"):
            withAnimation { currentStep = 3 }
            shakeField(5)
        default:
            // Default case
            break
        }
    }
}

// MARK: - Extensions

extension View {
    func shakeEffect(trigger: Bool) -> some View {
        modifier(ShakeEffect(trigger: trigger))
    }
}

struct ShakeEffect: ViewModifier {
    var trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: trigger ? 5 * sin(5 * .pi * 1.0) : 0)
            .animation(trigger ? .easeInOut(duration: 0.6).repeatCount(3, autoreverses: true) : .default, value: trigger)
    }
}

#Preview {
    SignUpView(authViewModel: AuthViewModel())
} 
