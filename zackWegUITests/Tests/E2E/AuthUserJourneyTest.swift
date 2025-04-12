import XCTest
@testable import zackWeg

class AuthUserJourneyTest: XCTestCase {
    var app: XCUIApplication!
    var testHelper: UITestHelper!
    
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
    
    // MARK: - Tests
    
    func testSignUpAndSignInFlow() {
        // Generate random 4 character string for uniqueness
        let randomChars = String((0..<4).map { _ in "abcdefghijklmnopqrstuvwxyz0123456789".randomElement()! })
        let username = "test_username_\(randomChars)"
        let email = "test_email_\(randomChars)@zackweg.com"
        let password = "123123123"
        
        // Wait for splash screen to finish
        sleep(3)
        
        // Find and tap the create account button
        let createAccountButton = app.buttons["createAccountButton"]
        XCTAssertTrue(createAccountButton.waitForExistence(timeout: 5), "Create account button should exist")
        createAccountButton.tap()
        
        // Wait for animation to complete (it's a sheet with animation)
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
            
            // If keyboard still present, tap outside
            if app.keyboards.count > 0 {
                let topOfScreen = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
                topOfScreen.tap()
                sleep(1)
            }
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
        
        // Go to settings and sign out
        let settingsTab = app.tabBars.buttons.element(boundBy: 3) // Assuming Settings is the 4th tab
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")
        settingsTab.tap()
        
        // Find and tap sign out button
        let signOutButton = app.buttons["signOutButton"]
        if !signOutButton.waitForExistence(timeout: 5) {
            // Try scrolling to find it
            let settingsScreen = app.scrollViews.firstMatch
            let coordinate = settingsScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
            coordinate.press(forDuration: 0.1, thenDragTo: settingsScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)))
            sleep(1)
        }
        
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5), "Sign out button should exist")
        signOutButton.tap()
        
        // Confirm sign out if dialog appears
        let confirmAlert = app.alerts.firstMatch
        if confirmAlert.waitForExistence(timeout: 3) {
            let confirmButton = confirmAlert.buttons.element(boundBy: 1)
            confirmButton.tap()
        }
        
        // Verify we're back on the sign in screen
        XCTAssertTrue(app.buttons["createAccountButton"].waitForExistence(timeout: 15), "Create account button should appear after sign out")
        
        // Now sign in with the same credentials
        let emailSignInField = app.textFields["emailTextField"]
        XCTAssertTrue(emailSignInField.waitForExistence(timeout: 5), "Email field should exist")
        emailSignInField.tap()
        emailSignInField.typeText(email)
        
        let passwordSignInField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordSignInField.waitForExistence(timeout: 5), "Password field should exist")
        passwordSignInField.tap()
        passwordSignInField.typeText(password)
        
        // Tap sign in button
        let signInButton = app.buttons["signInButton"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign in button should exist")
        signInButton.tap()
        
        // Verify we're logged in again
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "Tab bar should appear after successful sign in")
        
        // Go to settings and sign out again
        settingsTab.tap()
        
        // Find and tap sign out button again
        if !signOutButton.waitForExistence(timeout: 5) {
            // Try scrolling to find it
            let settingsScreen = app.scrollViews.firstMatch
            let coordinate = settingsScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
            coordinate.press(forDuration: 0.1, thenDragTo: settingsScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)))
            sleep(1)
        }
        
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5), "Sign out button should exist")
        signOutButton.tap()
        
        // Confirm sign out if dialog appears
        if confirmAlert.waitForExistence(timeout: 3) {
            let confirmButton = confirmAlert.buttons.element(boundBy: 1)
            confirmButton.tap()
        }
        
        // Verify we're back on the sign in screen
        XCTAssertTrue(app.buttons["createAccountButton"].waitForExistence(timeout: 15), "Create account button should appear after sign out")
        
        // Test forgot password
        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        XCTAssertTrue(forgotPasswordButton.waitForExistence(timeout: 5), "Forgot password button should exist")
        forgotPasswordButton.tap()
        
        // Verify we're on forgot password screen
        let forgotPasswordEmailField = app.textFields["forgotPasswordEmailTextField"]
        XCTAssertTrue(forgotPasswordEmailField.waitForExistence(timeout: 5), "Forgot password email field should exist")
        
        // Enter email and submit
        forgotPasswordEmailField.tap()
        forgotPasswordEmailField.typeText(email)
        
        let resetPasswordButton = app.buttons["resetPasswordButton"]
        XCTAssertTrue(resetPasswordButton.waitForExistence(timeout: 5), "Reset password button should exist")
        resetPasswordButton.tap()
        
        // Verify reset password success message appears as an alert
        let resetSuccessAlert = app.alerts.firstMatch
        XCTAssertTrue(resetSuccessAlert.waitForExistence(timeout: 10), "Reset password success alert should appear")
        
        // Dismiss the success alert
        if resetSuccessAlert.exists {
            // Find the OK button or similar on the alert
            let okButton = resetSuccessAlert.buttons.firstMatch
            if okButton.exists {
                okButton.tap()
            }
        }
        
        // Return to sign in screen
        let backToSignInButton = app.buttons["backToSignInButton"]
        if backToSignInButton.waitForExistence(timeout: 5) {
            backToSignInButton.tap()
        }
        
        // Verify we're back on the sign in screen
        XCTAssertTrue(app.buttons["createAccountButton"].waitForExistence(timeout: 15), "Create account button should appear after forgot password flow")
    }
}

// Extension to help with scrolling to elements
extension XCUIElement {
    /// Scrolls to make the element visible
    func scrollToElement(_ element: XCUIElement) {
        var previousRect = self.frame
        
        while !element.isHittable {
            swipeUp()
            
            // Check if we've stopped scrolling (reached the end)
            let currentRect = self.frame
            if previousRect == currentRect {
                break
            }
            previousRect = currentRect
            
            // Wait a moment for scrolling to stabilize
            sleep(1)
            
            if element.isHittable {
                break
            }
        }
    }
    
    /// Checks if the element has keyboard focus
    func hasFocus() -> Bool {
        // Check if element has focus by looking at keyboard
        return self.value(forKey: "hasKeyboardFocus") as? Bool ?? false
    }
} 
