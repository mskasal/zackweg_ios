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
        enterText(password, in: passwordField)
        enterText(password, in: confirmPasswordField)
        
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
        enterText(password, in: passwordField)
        signInButton.tap()
        
        // Handle any alert that might appear
        handleAlert(acceptButtons: ["OK", "Continue", "Accept"])
        
        // Wait for sign in to complete (tab bar appears)
        return waitForElement(app.tabBars.firstMatch)
    }
    
    // MARK: - Element Finder
    
    /// Finds an element using multiple strategies
    /// - Parameters:
    ///   - types: Element types to search (button, textField, etc.)
    ///   - identifiers: Accessibility identifiers to try
    ///   - predicates: Additional predicates to use if identifiers fail
    /// - Returns: The found XCUIElement (may or may not exist)
    func findElement(types: [XCUIElement.ElementType], identifiers: [String], predicates: [NSPredicate]? = nil) -> XCUIElement {
        // First try to find by accessibility identifier
        for identifier in identifiers {
            for type in types {
                let query = app.descendants(matching: type)
                let element = query[identifier]
                if element.exists {
                    return element
                }
            }
        }
        
        // If not found, try predicates
        if let predicates = predicates {
            for predicate in predicates {
                for type in types {
                    let query = app.descendants(matching: type)
                    let matchingElements = query.matching(predicate)
                    if matchingElements.count > 0 {
                        return matchingElements.element(boundBy: 0)
                    }
                }
            }
        }
        
        // If no match, return the first element of the first type
        // (this will likely fail gracefully when trying to interact with it)
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