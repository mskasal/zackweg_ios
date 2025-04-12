import XCTest
@testable import zackWeg

class SettingsUserJourneyTest: XCTestCase {
    var app: XCUIApplication!
    var testHelper: UITestHelper!
    
    // Test user credentials
    var username: String!
    var email: String!
    var password: String!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        // Reset user state before testing
        resetUserData()
        
        app = XCUIApplication()
        testHelper = UITestHelper(app: app)
        
        // Enable UI testing mode
        app.launchArguments = [
            "--uitesting", 
            "--reset-state",
            // Disable password autofill features
            "-AppleIDAppleIDPasswordEnabled", "NO",
            "-AppleKeyboardAutomaticPasswordEnabled", "NO",
            "-AppleIDKeychainPasswordEnabled", "NO",
            "-AppleICloudKeychainItemSuggestionsEnabled", "NO",
            "-AppleKeychainItemSuggestionsEnabled", "NO",
            "-ApplePasswordManagerUIEnabled", "NO",
            "-ApplePasswordManagerProtectedUIEnabled", "NO",
            "-ApplePasswordSheetEnabled", "NO",
        ]
        app.launchEnvironment = [
            "UI_TEST_MODE": "1",
            "DISABLE_AUTOFILL": "1",
            "DISABLE_PASSWORD_MANAGER": "1"
        ]
        
        // Generate random test data for uniqueness
        let randomChars = String((0..<4).map { _ in "abcdefghijklmnopqrstuvwxyz0123456789".randomElement()! })
        username = "test_user_\(randomChars)"
        email = "test_email_\(randomChars)@zackweg.com"
        password = "Password123!"
        
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        testHelper = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Resets user data by clearing keychain and UserDefaults
    private func resetUserData() {
        // Clear keychain items
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for secItemClass in secItemClasses {
            let query = [kSecClass: secItemClass]
            SecItemDelete(query as CFDictionary)
        }
        
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    /// Force clears any auto-filled password and enters the desired text
    private func forceClearAndEnterPassword(field: XCUIElement, text: String) {
        // First tap the field to focus it
        field.tap()
        
        // Select all text (will select auto-filled password if present)
        field.press(forDuration: 1.5)
        
        // Try the "Select All" button if it appears
        let selectAllButton = app.menuItems["Select All"]
        if selectAllButton.waitForExistence(timeout: 1) {
            selectAllButton.tap()
        } else {
            // Alternative: Double-tap often selects all in password fields
            field.doubleTap()
        }
        
        // Delete any existing text
        field.typeText(XCUIKeyboardKey.delete.rawValue)
        
        // Verify field is empty and then enter our password
        Thread.sleep(forTimeInterval: 0.5)
        field.typeText(text)
        
        // Immediately dismiss any password suggestion UI
        dismissPasswordSuggestionUI()
    }
    
    private func dismissPasswordSuggestionUI() {
        // Tap outside to dismiss any suggestion UI
        let topOfScreen = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        topOfScreen.tap()
        
        // Look for and dismiss Save Password dialog 
        let notNowButton = app.buttons["Not Now"]
        if notNowButton.waitForExistence(timeout: 0.5) {
            notNowButton.tap()
        }
        
        // Attempt to dismiss strong password suggestion dialog
        let useStrongPasswordButton = app.buttons["Use Strong Password"]
        if useStrongPasswordButton.waitForExistence(timeout: 0.5) {
            // Look for "Choose My Own Password" option instead
            let chooseMyOwnButton = app.buttons["Choose My Own Password"]
            if chooseMyOwnButton.waitForExistence(timeout: 0.5) {
                chooseMyOwnButton.tap()
            } else {
                // Tap elsewhere to dismiss
                topOfScreen.tap()
            }
        }
    }
    
    private func signUpTestUser() {
        // Wait for splash screen to finish
        sleep(3)
        
        // Find and tap the create account button
        let createAccountButton = app.buttons["createAccountButton"]
        XCTAssertTrue(createAccountButton.waitForExistence(timeout: 5), "Create account button should exist")
        createAccountButton.tap()
        
        // Wait for animation to complete
        sleep(3)
        
        // Fill in the form fields in sequence
        
        // 1. Nickname field
        let nicknameField = app.textFields["signUpNameTextField"]
        if nicknameField.waitForExistence(timeout: 3) {
            nicknameField.tap()
            nicknameField.typeText(username)
            app.buttons["Next"].tap() // Tap keyboard navigator
            sleep(1)
        }
        
        // 2. Email field
        let emailField = app.textFields["signUpEmailTextField"]
        if emailField.waitForExistence(timeout: 3) {
            emailField.tap()
            emailField.typeText(email)
            app.buttons["Next"].tap() // Tap keyboard navigator
            sleep(1)
        }
        
        // 3. Postal code field
        let postalCodeField = app.textFields["signUpPostalCodeTextField"]
        if postalCodeField.waitForExistence(timeout: 3) {
            postalCodeField.tap()
            
            // For numeric keyboard, tap each digit separately
            let postalCode = "10317"
            for digit in postalCode {
                app.keyboards.keys[String(digit)].tap()
                // Use an integer value for sleep
                sleep(1)
            }
            
            app.buttons["Next"].tap() // Tap keyboard navigator
            sleep(1)
        }
        
        // 4. Password field
        let passwordField = app.secureTextFields["signUpPasswordTextField"]
        if passwordField.waitForExistence(timeout: 3) {
            passwordField.tap()
            passwordField.typeText(password)
            // Dismiss keyboard
            app.buttons["Done"].tap()
            sleep(1)
        }
        
        // Tap sign-up button
        let signUpButton = app.buttons["signUpConfirmButton"]
        if signUpButton.waitForExistence(timeout: 5) {
            signUpButton.tap()
            sleep(5) // Wait for sign-up process
        }
        
        // Handle any alert that might appear
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 3) {
            alert.buttons.firstMatch.tap()
        }
        
        // Verify we're logged in by checking for tab bar
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "Tab bar should appear after successful sign up")
    }
    
    // MARK: - Test Cases
    
    func testSettingsFlow() {
        // First sign up a test user
        signUpTestUser()
        
        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons.element(boundBy: 3) // Assuming Settings is the 4th tab
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")
        settingsTab.tap()
        
        // Add a small delay to ensure navigation completes
        sleep(2)
        
        // Verify the settings screen has loaded by checking for key UI elements
        let userProfileHeader = testHelper.findElement(
            types: [.other],
            identifiers: ["userProfileHeader"]
        )
        let nicknameText = testHelper.findElement(
            types: [.staticText],
            identifiers: ["userNicknameText"]
        )
        let emailText = testHelper.findElement(
            types: [.staticText],
            identifiers: ["userEmailText"]
        )
        let updateProfileButton = testHelper.findElement(
            types: [.button],
            identifiers: ["updateProfileButton"]
        )
        let updatePasswordButton = testHelper.findElement(
            types: [.button],
            identifiers: ["updatePasswordButton"]
        )
        let themeSelector = testHelper.findElement(
            types: [.other],
            identifiers: ["themeSelector"]
        )
        
        // Check that at least the main UI elements exist
        XCTAssertTrue(testHelper.waitForElement(userProfileHeader), "User profile header should be displayed")
        XCTAssertTrue(testHelper.waitForElement(nicknameText), "User nickname should be displayed")
        XCTAssertTrue(testHelper.waitForElement(emailText), "User email should be displayed")
        XCTAssertTrue(testHelper.waitForElement(updateProfileButton), "Update profile button should exist")
        
        // Test theme selection
        XCTAssertTrue(testHelper.waitForElement(themeSelector), "Theme selector should exist")
        themeSelector.tap()
        
        // Tap on Dark theme if it exists in the menu
        let darkThemeButton = testHelper.findElement(
            types: [.button],
            identifiers: ["themeOption_dark"]
        )
        if testHelper.waitForElement(darkThemeButton) {
            darkThemeButton.tap()
            sleep(2) // Wait for theme to apply
        }
        
        // Test language selection
        let languageSelector = testHelper.findElement(
            types: [.other],
            identifiers: ["languageSelector"]
        )
        XCTAssertTrue(testHelper.waitForElement(languageSelector), "Language selector should exist")
        languageSelector.tap()
        
        // Tap on German language if available
        let germanLanguageButton = testHelper.findElement(
            types: [.button],
            identifiers: ["languageOption_de"]
        )
        if testHelper.waitForElement(germanLanguageButton) {
            germanLanguageButton.tap()
            sleep(2) // Wait for language to apply
        }
        
        // Test update profile flow
        testUpdateProfileFlow()
        
        // Test update password flow
        testUpdatePasswordFlow()
        
        // Test supporting links
        let helpButton = testHelper.findElement(
            types: [.button],
            identifiers: ["helpSupportButton"]
        )
        XCTAssertTrue(testHelper.waitForElement(helpButton), "Help button should exist")
        
        let termsButton = testHelper.findElement(
            types: [.button],
            identifiers: ["termsButton"]
        )
        XCTAssertTrue(testHelper.waitForElement(termsButton), "Terms button should exist")
        
        let privacyButton = testHelper.findElement(
            types: [.button],
            identifiers: ["privacyButton"]
        )
        XCTAssertTrue(testHelper.waitForElement(privacyButton), "Privacy button should exist")
        
        // Check app version is displayed
        let versionRow = testHelper.findElement(
            types: [.other],
            identifiers: ["appVersionRow"]
        )
        XCTAssertTrue(testHelper.waitForElement(versionRow), "App version row should be displayed")
        
        let versionValue = testHelper.findElement(
            types: [.staticText],
            identifiers: ["appVersionValue"]
        )
        XCTAssertTrue(testHelper.waitForElement(versionValue), "App version value should be displayed")
        
        // Finally, test sign out
        testSignOut()
    }
    
    private func testUpdateProfileFlow() {
        // Test update profile flow
        let updateProfileButton = testHelper.findElement(
            types: [.button],
            identifiers: ["updateProfileButton"]
        )
        XCTAssertTrue(testHelper.waitForElement(updateProfileButton), "Update Profile button should exist")
        updateProfileButton.tap()
        
        // Find and interact with input fields
        let emailField = testHelper.findElement(
            types: [.textField],
            identifiers: ["profileEmailField"]
        )
        if testHelper.waitForElement(emailField) {
            emailField.tap()
            emailField.clearText() // Helper method, implement if needed
            emailField.typeText("updated_\(email)")
            sleep(1)
        }
        
        let postalCodeField = testHelper.findElement(
            types: [.textField],
            identifiers: ["profilePostalCodeField"]
        )
        if testHelper.waitForElement(postalCodeField) {
            postalCodeField.tap()
            postalCodeField.clearText() // Helper method, implement if needed 
            postalCodeField.typeText("12345")
            sleep(1)
        }
        
        // Try to save the profile
        let saveButton = testHelper.findElement(
            types: [.button],
            identifiers: ["saveProfileButton"]
        )
        if testHelper.waitForElement(saveButton) {
            saveButton.tap()
            sleep(2) // Wait for save to complete
        }
        
        // If there's no automatic dismiss, cancel manually
        let cancelButton = testHelper.findElement(
            types: [.button],
            identifiers: ["cancelProfileUpdateButton"]
        )
        if testHelper.waitForElement(cancelButton) {
            cancelButton.tap()
        }
        
        // Verify we're back on the settings screen by checking for specific elements
        let settingsHeader = testHelper.findElement(
            types: [.other],
            identifiers: ["userProfileHeader"]
        )
        XCTAssertTrue(testHelper.waitForElement(settingsHeader), "Should return to settings screen")
    }
    
    private func testUpdatePasswordFlow() {
        // Test update password flow
        let updatePasswordButton = testHelper.findElement(
            types: [.button],
            identifiers: ["updatePasswordButton"]
        )
        XCTAssertTrue(testHelper.waitForElement(updatePasswordButton), "Update Password button should exist")
        updatePasswordButton.tap()
        
        // Verify we're on the update password screen
        let updatePasswordScreen = testHelper.findElement(
            types: [.other],
            identifiers: ["updatePasswordScreen"]
        )
        XCTAssertTrue(testHelper.waitForElement(updatePasswordScreen), "Update Password screen should appear")
        
        // Fill in the password fields
        let currentPasswordField = testHelper.findElement(
            types: [.secureTextField],
            identifiers: ["currentPasswordField"]
        )
        if testHelper.waitForElement(currentPasswordField) {
            forceClearAndEnterPassword(field: currentPasswordField, text: password)
        }
        
        let newPasswordField = testHelper.findElement(
            types: [.secureTextField],
            identifiers: ["newPasswordField"]
        )
        if testHelper.waitForElement(newPasswordField) {
            forceClearAndEnterPassword(field: newPasswordField, text: "NewPassword123!")
        }
        
        let confirmPasswordField = testHelper.findElement(
            types: [.secureTextField],
            identifiers: ["confirmPasswordField"]
        )
        if testHelper.waitForElement(confirmPasswordField) {
            forceClearAndEnterPassword(field: confirmPasswordField, text: "NewPassword123!")
        }
        
        // Check password strength indicator
        let strengthIndicator = testHelper.findElement(
            types: [.other],
            identifiers: ["passwordStrengthIndicator"]
        )
        XCTAssertTrue(testHelper.waitForElement(strengthIndicator), "Password strength indicator should be visible")
        
        // Try to save the password
        let saveButton = testHelper.findElement(
            types: [.button],
            identifiers: ["savePasswordButton"]
        )
        if testHelper.waitForElement(saveButton) {
            saveButton.tap()
            sleep(2) // Wait for save to complete
        }
        
        // If there's no automatic dismiss, cancel manually
        let cancelButton = testHelper.findElement(
            types: [.button],
            identifiers: ["cancelPasswordUpdateButton"]
        )
        if testHelper.waitForElement(cancelButton) {
            cancelButton.tap()
        }
        
        // Verify we're back on the settings screen by checking for specific elements
        let settingsHeader = testHelper.findElement(
            types: [.other],
            identifiers: ["userProfileHeader"]
        )
        XCTAssertTrue(testHelper.waitForElement(settingsHeader), "Should return to settings screen")
    }
    
    private func testSignOut() {
        let signOutButton = testHelper.findElement(
            types: [.button],
            identifiers: ["signOutButton"]
        )
        
        // Scroll to find sign out button if not visible
        if !testHelper.waitForElement(signOutButton) {
            // Try scrolling to find it
            let settingsScreenList = testHelper.findElement(
                types: [.scrollView],
                identifiers: ["settingsScrollView"]
            )
            let coordinate = settingsScreenList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
            coordinate.press(forDuration: 0.1, thenDragTo: settingsScreenList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)))
            sleep(1)
        }
        
        XCTAssertTrue(testHelper.waitForElement(signOutButton), "Sign out button should exist")
        signOutButton.tap()
        
        // Confirm sign out if dialog appears
        let confirmAlert = app.alerts.firstMatch
        if confirmAlert.waitForExistence(timeout: 3) {
            let confirmButton = confirmAlert.buttons.element(boundBy: 1)
            confirmButton.tap()
        }
        
        // Verify we're back on the sign in screen
        let createAccountButton = testHelper.findElement(
            types: [.button],
            identifiers: ["createAccountButton"]
        )
        XCTAssertTrue(testHelper.waitForElement(createAccountButton, timeout: 15), "Create account button should appear after sign out")
    }
}

// Helper extension to clear text in a field
extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        // Select all and delete
        tap()
        press(forDuration: 1)
        
        let selectAll = self.buttons["Select All"].firstMatch
        if selectAll.exists {
            selectAll.tap()
            typeText(XCUIKeyboardKey.delete.rawValue)
        } else {
            // Fallback: tap and delete characters one by one
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            typeText(deleteString)
        }
    }
} 
