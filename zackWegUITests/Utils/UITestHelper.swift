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
            
            let signOutButton = app.buttons["signOutButton"]
            if signOutButton.exists {
                signOutButton.tap()
                // Confirm sign out if a confirmation dialog appears
                if app.alerts.buttons["Sign Out"].exists {
                    app.alerts.buttons["Sign Out"].tap()
                }
            }
        }
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
        return app.textFields["emailTextField"].exists &&
               app.secureTextFields["passwordTextField"].exists &&
               app.buttons["signInButton"].exists
    }
    
    /// Verifies if we are logged in (tab bar is visible)
    func isLoggedIn() -> Bool {
        return app.tabBars.firstMatch.exists
    }
    
    /// Dismisses any alert that might be showing
    func dismissAlertIfPresent() {
        if app.alerts.buttons["OK"].exists {
            app.alerts.buttons["OK"].tap()
        }
    }
} 
