import XCTest
@testable import zackWeg

/// Helper class providing common functionality for UI testing
class UITestHelper {
    /// The app under test
    let app: XCUIApplication
    
    /// Default timeout for waiting operations
    let defaultTimeout: TimeInterval = 5.0
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    // MARK: - Navigation Helpers
    
    /// Navigates to sign in screen
    func navigateToSignIn() {
        // If already logged in, sign out first
        if app.tabBars.firstMatch.exists {
            let settingsTab = app.tabBars.buttons.element(boundBy: 3)
            settingsTab.tap()
            
            // Look for sign out button with multiple possible identifiers
            let signOutButton = findElement(
                types: [.button],
                identifiers: ["signOutButton", "logoutButton"],
                predicates: [NSPredicate(format: "label CONTAINS 'Sign Out' OR label CONTAINS 'Log Out'")]
            )
            
            if signOutButton.exists {
                signOutButton.tap()
                // Confirm sign out if a confirmation dialog appears
                handleAlert(acceptButtons: ["Sign Out", "Log Out", "OK", "Yes"])
            }
        }
    }
    
    /// Navigates to the registration screen from sign in
    func navigateToRegistration() {
        if !isOnSignInScreen() {
            navigateToSignIn()
        }
        
        let createAccountButton = findElement(
            types: [.button],
            identifiers: ["createAccountButton", "registerButton", "signUpButton"],
            predicates: [NSPredicate(format: "label CONTAINS 'Create Account' OR label CONTAINS 'Sign Up' OR label CONTAINS 'Register'")]
        )
        
        if waitForElement(createAccountButton) {
            createAccountButton.tap()
        }
    }
    
    // MARK: - Registration Helper
    
    /// Registers a new user with the provided information
    func registerNewUser(email: String, password: String, username: String, fullName: String) -> Bool {
        // Navigate to registration screen
        navigateToRegistration()
        
        // Wait for registration screen to appear
        let registerButton = findElement(
            types: [.button],
            identifiers: ["registerButton", "signUpButton", "createAccountButton"],
            predicates: [NSPredicate(format: "label CONTAINS 'Register' OR label CONTAINS 'Sign Up' OR label CONTAINS 'Create'")]
        )
        
        guard waitForElement(registerButton) else {
            return false
        }
        
        // Fill in the registration form
        let fullNameField = findElement(
            types: [.textField],
            identifiers: ["fullNameTextField", "nameTextField"],
            predicates: [NSPredicate(format: "placeholderValue CONTAINS 'name' OR placeholderValue CONTAINS 'Name'")]
        )
        
        let emailField = findElement(
            types: [.textField],
            identifiers: ["emailTextField"],
            predicates: [NSPredicate(format: "placeholderValue CONTAINS 'email' OR placeholderValue CONTAINS 'Email'")]
        )
        
        let usernameField = findElement(
            types: [.textField],
            identifiers: ["usernameTextField"],
            predicates: [NSPredicate(format: "placeholderValue CONTAINS 'username' OR placeholderValue CONTAINS 'Username'")]
        )
        
        let passwordField = findElement(
            types: [.secureTextField],
            identifiers: ["passwordTextField"],
            predicates: [NSPredicate(format: "placeholderValue CONTAINS 'password' OR placeholderValue CONTAINS 'Password'")]
        )
        
        let confirmPasswordField = findElement(
            types: [.secureTextField],
            identifiers: ["confirmPasswordTextField", "verifyPasswordTextField"],
            predicates: [NSPredicate(format: "placeholderValue CONTAINS 'confirm' OR placeholderValue CONTAINS 'verify' OR placeholderValue CONTAINS 'Confirm'")]
        )
        
        enterText(fullName, in: fullNameField)
        enterText(email, in: emailField)
        enterText(username, in: usernameField)
        forceClearAndEnterPassword(field: passwordField, text: password)
        forceClearAndEnterPassword(field: confirmPasswordField, text: password)
        
        registerButton.tap()
        
        // Handle any alert that might appear (like terms acceptance)
        handleAlert(acceptButtons: ["Accept", "OK", "Yes", "Continue"])
        
        // Wait for registration to complete (tab bar appears)
        return waitForElement(app.tabBars.firstMatch)
    }
    
    // MARK: - Sign In Helper
    
    /// Signs in with the provided email and password
    func signIn(email: String, password: String) -> Bool {
        if !isOnSignInScreen() {
            navigateToSignIn()
        }
        
        let emailField = findElement(
            types: [.textField],
            identifiers: ["emailTextField"],
            predicates: [NSPredicate(format: "placeholderValue CONTAINS 'email' OR placeholderValue CONTAINS 'Email'")]
        )
        
        let passwordField = findElement(
            types: [.secureTextField],
            identifiers: ["passwordTextField"],
            predicates: [NSPredicate(format: "placeholderValue CONTAINS 'password' OR placeholderValue CONTAINS 'Password'")]
        )
        
        let signInButton = findElement(
            types: [.button],
            identifiers: ["signInButton", "loginButton"],
            predicates: [NSPredicate(format: "label CONTAINS 'Sign In' OR label CONTAINS 'Log In' OR label CONTAINS 'Login'")]
        )
        
        guard waitForElement(emailField),
              waitForElement(passwordField),
              waitForElement(signInButton) else {
            return false
        }
        
        enterText(email, in: emailField)
        forceClearAndEnterPassword(field: passwordField, text: password)
        signInButton.tap()
        
        // Handle any alert that might appear
        handleAlert(acceptButtons: ["OK", "Continue", "Accept"])
        
        // Wait for sign in to complete (tab bar appears)
        return waitForElement(app.tabBars.firstMatch)
    }
    
    // MARK: - Element Finder
    
    /// Finds an element by trying multiple approaches
    /// - Parameters:
    ///   - types: The element types to look for (buttons, text fields, etc.)
    ///   - identifiers: Accessibility identifiers to match
    ///   - predicates: Predicates to match
    /// - Returns: The first matching element, or the first element of the first type if no matches
    func findElement(types: [XCUIElement.ElementType], identifiers: [String] = [], predicates: [NSPredicate] = []) -> XCUIElement {
        // First try direct access by identifier (most efficient)
        for identifier in identifiers {
            let element = app.descendants(matching: .any)["**/\(identifier)"]
            if element.exists {
                return element
            }
            
            // Also try direct access without regex pattern
            let directElement = app.descendants(matching: .any)[identifier]
            if directElement.exists {
                return directElement
            }
        }
        
        // Try each element type
        for type in types {
            // Try accessibility identifiers
            for identifier in identifiers {
                let matchingElements = app.descendants(matching: type).matching(identifier: identifier)
                if matchingElements.count > 0 {
                    return matchingElements.element(boundBy: 0)
                }
            }
            
            // Try predicates
            for predicate in predicates {
                let query = app.descendants(matching: type)
                let matchingElements = query.matching(predicate)
                if matchingElements.count > 0 {
                    return matchingElements.element(boundBy: 0)
                }
            }
        }
        
        // Fallback to first element of first type if nothing found
        return app.descendants(matching: types.first!).element(boundBy: 0)
    }
    
    // MARK: - Alert Handler
    
    /// Handles various types of alerts by trying different button options
    /// - Parameter acceptButtons: Array of possible button titles to accept the alert
    /// - Returns: True if an alert was handled
    @discardableResult
    func handleAlert(acceptButtons: [String]) -> Bool {
        // Wait a moment for any alert to appear
        sleep(1)
        
        let alert = app.alerts.firstMatch
        if alert.exists {
            // Try each button option
            for buttonTitle in acceptButtons {
                let button = alert.buttons[buttonTitle]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            
            // If none of the specified buttons exist, try the first button
            if alert.buttons.count > 0 {
                alert.buttons.element(boundBy: 0).tap()
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Input Helpers
    
    /// Enters text into a text field
    func enterText(_ text: String, in textField: XCUIElement) {
        textField.tap()
        textField.typeText(text)
    }
    
    /// Force clears any auto-filled password and enters the desired text
    func forceClearAndEnterPassword(field: XCUIElement, text: String) {
        // First tap the field to focus it
        field.tap()
        
        // Pause to allow any suggestion UI to appear
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check for and dismiss "Use Strong Password" button
        let useStrongPasswordButton = app.buttons["Use Strong Password"]
        if useStrongPasswordButton.waitForExistence(timeout: 0.5) {
            let chooseMyOwnButton = app.buttons["Choose My Own Password"]
            if chooseMyOwnButton.waitForExistence(timeout: 0.5) {
                chooseMyOwnButton.tap()
            } else {
                // Tap away from the keyboard
                let topOfScreen = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
                topOfScreen.tap()
                
                // Tap field again
                field.tap()
            }
        }
        
        // Check for keyboard and make sure it's visible
        if !app.keyboards.firstMatch.exists {
            field.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Select all text using multiple methods
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
        
        // Insert a small delay to ensure deletion completed
        Thread.sleep(forTimeInterval: 0.5)
        
        // Enter our password text character by character with small delays
        for char in text {
            field.typeText(String(char))
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Dismiss any suggestion UI that might have appeared
        dismissPasswordSuggestionUI()
    }
    
    /// Dismisses any password suggestion UI that appears
    func dismissPasswordSuggestionUI() {
        // Check for iOS 18 password AutoFill toolbar
        let autoFillButton = app.buttons["AutoFill Password"]
        if autoFillButton.waitForExistence(timeout: 0.5) {
            // Tap on "Not Now" if available
            let notNowButton = app.buttons["Not Now"]
            if notNowButton.waitForExistence(timeout: 0.5) {
                notNowButton.tap()
            } else {
                // Tap away from the keyboard/toolbar
                let topOfScreen = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
                topOfScreen.tap()
            }
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
                let topOfScreen = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
                topOfScreen.tap()
            }
        }
        
        // Handle "Save Password" dialog
        let savePasswordAlert = app.alerts["Save Password"]
        if savePasswordAlert.waitForExistence(timeout: 0.5) {
            let notNowButton = savePasswordAlert.buttons["Not Now"]
            if notNowButton.waitForExistence(timeout: 0.5) {
                notNowButton.tap()
            } else {
                // Try to tap the Cancel button if "Not Now" doesn't exist
                let cancelButton = savePasswordAlert.buttons["Cancel"]
                if cancelButton.waitForExistence(timeout: 0.5) {
                    cancelButton.tap()
                }
            }
        }
    }
    
    /// Clears text from a text field
    func clearTextField(_ textField: XCUIElement) {
        textField.tap()
        
        // Select all text
        textField.press(forDuration: 1.0)
        
        // Tap "Select All" if it appears
        if app.menuItems["Select All"].exists {
            app.menuItems["Select All"].tap()
        }
        
        // Delete the text
        textField.typeText(XCUIKeyboardKey.delete.rawValue)
    }
    
    // MARK: - Wait Helpers
    
    /// Waits for an element to exist
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval? = nil) -> Bool {
        let timeoutValue = timeout ?? defaultTimeout
        let exists = NSPredicate(format: "exists == true")
        
        let expectation = XCTNSPredicateExpectation(predicate: exists, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeoutValue)
        
        return result == .completed
    }
    
    /// Waits for an element to be hittable (visible and enabled)
    func waitForElementToBeHittable(_ element: XCUIElement, timeout: TimeInterval? = nil) -> Bool {
        let timeoutValue = timeout ?? defaultTimeout
        let hittable = NSPredicate(format: "isHittable == true")
        
        let expectation = XCTNSPredicateExpectation(predicate: hittable, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeoutValue)
        
        return result == .completed
    }
    
    // MARK: - Verification Helpers
    
    /// Verifies if we are on the sign in screen
    func isOnSignInScreen() -> Bool {
        // Look for key sign in elements using multiple approaches
        let emailField = findElement(
            types: [.textField],
            identifiers: ["emailTextField"],
            predicates: [NSPredicate(format: "placeholderValue CONTAINS 'email' OR placeholderValue CONTAINS 'Email'")]
        )
        
        let passwordField = findElement(
            types: [.secureTextField],
            identifiers: ["passwordTextField"],
            predicates: [NSPredicate(format: "placeholderValue CONTAINS 'password' OR placeholderValue CONTAINS 'Password'")]
        )
        
        let signInButton = findElement(
            types: [.button],
            identifiers: ["signInButton", "loginButton"],
            predicates: [NSPredicate(format: "label CONTAINS 'Sign In' OR label CONTAINS 'Log In' OR label CONTAINS 'Login'")]
        )
        
        return emailField.exists && passwordField.exists && signInButton.exists
    }
    
    /// Verifies if we are logged in (tab bar is visible)
    func isLoggedIn() -> Bool {
        return app.tabBars.firstMatch.exists
    }
    
    /// Dismisses any alert that might be showing
    func dismissAlertIfPresent() {
        handleAlert(acceptButtons: ["OK", "Cancel", "Close", "Dismiss"])
    }
} 