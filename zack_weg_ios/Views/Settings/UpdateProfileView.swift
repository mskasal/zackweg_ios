import SwiftUI

struct UpdateProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    
    // User data state variables
    @State private var email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
    @State private var postalCode = UserDefaults.standard.string(forKey: "postalCode") ?? ""
    @State private var countryCode = UserDefaults.standard.string(forKey: "countryCode") ?? "DEU"
    
    // Original values to check for changes
    @State private var originalEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
    @State private var originalPostalCode = UserDefaults.standard.string(forKey: "postalCode") ?? ""
    @State private var originalCountryCode = UserDefaults.standard.string(forKey: "countryCode") ?? "DEU"
    
    // UI state variables
    @State private var showSuccess = false
    
    // List of countries
    private let countries = [
        ("DEU", "Germany")
    ]
    
    private var hasChanges: Bool {
        return email != originalEmail || 
               postalCode != originalPostalCode || 
               countryCode != originalCountryCode
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("settings.personal_information".localized)) {
                        HStack {
                            Text("profile.email".localized)
                                .foregroundColor(.secondary)
                            
                            TextField("profile.email".localized, text: $email)
                                .multilineTextAlignment(.trailing)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocapitalization(.none)
                        }
                    }
                    
                    Section(header: Text("settings.location".localized)) {
                        HStack {
                            Text("profile.postal_code".localized)
                                .foregroundColor(.secondary)
                            
                            TextField("profile.postal_code".localized, text: $postalCode)
                                .multilineTextAlignment(.trailing)
                                .autocorrectionDisabled()
                                .keyboardType(.numberPad)
                        }
                        
                        Picker("profile.country".localized, selection: $countryCode) {
                            ForEach(countries, id: \.0) { code, name in
                                Text(name).tag(code)
                            }
                        }
                    }
                    
                    // Validation error messages
                    Group {
                        if !isValidEmail(email) && !email.isEmpty {
                            Section {
                                Text("settings.invalid_email".localized)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        
                        if postalCode.isEmpty {
                            Section {
                                Text("settings.postal_code_empty".localized)
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    if let error = viewModel.error {
                        Section {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("common.error".localized)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if viewModel.isLoading {
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
            .navigationTitle("settings.update_profile".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(!isValid || viewModel.isLoading)
                    .opacity(isValid ? 1.0 : 0.5)
                }
            }
            .onChange(of: email) { _ in
                viewModel.error = nil
                showSuccess = false
            }
            .onChange(of: postalCode) { _ in
                viewModel.error = nil
                showSuccess = false
            }
            .onChange(of: countryCode) { _ in
                viewModel.error = nil
                showSuccess = false
            }
            .onAppear {
                Task {
                    await loadUserProfile()
                }
            }
            .alert("settings.profile_updated".localized, isPresented: $showSuccess) {
                Button("common.ok".localized, role: .cancel) {}
            } message: {
                Text("settings.profile_update_success".localized)
            }
        }
    }
    
    private var isValid: Bool {
        return hasChanges && 
               (email.isEmpty || isValidEmail(email)) && 
               !postalCode.isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func loadUserProfile() async {
        do {
            let user = try await viewModel.getMyProfile()
            
            // Update state with the loaded profile
            email = user.email
            originalEmail = user.email
            
            postalCode = user.location.postalCode
            originalPostalCode = user.location.postalCode
            
            countryCode = user.location.countryCode
            originalCountryCode = user.location.countryCode
        } catch {
            self.viewModel.error = "Failed to load profile: \(error.localizedDescription)"
        }
    }
    
    private func saveProfile() async {
        viewModel.error = nil
        
        do {
            // Always send all values, not just the changed ones
            let user = try await viewModel.updateProfile(
                email: email,
                postalCode: postalCode,
                countryCode: countryCode
            )
            
            // Update original values with the new ones
            originalEmail = user.email
            originalPostalCode = user.location.postalCode
            originalCountryCode = user.location.countryCode
            
            // Show success message with standard alert
            showSuccess = true
            
            // Dismiss after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            self.viewModel.error = error.localizedDescription
        }
    }
}

#Preview {
    UpdateProfileView()
}