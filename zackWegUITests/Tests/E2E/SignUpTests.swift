import XCTest
@testable import zackWeg

class SignUpTests: XCTestCase {
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
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launchEnvironment = ["UI_TEST_MODE": "1"]
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
    
    func testSignUpWithSpecificData() {
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
            nicknameField.typeText("samed_test_3")
            app.buttons["Next"].tap() // Tap keyboard navigator
            sleep(1)
        }
        
        // 2. Email field
        let emailField = app.textFields["signUpEmailTextField"]
        if emailField.waitForExistence(timeout: 3) {
            emailField.tap()
            emailField.typeText("samed_test_3@zackweg.com")
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
            passwordField.typeText("123123123")
            
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
            sleep(2) // Wait for sign-up process
        }
        
        // Handle any alert that might appear
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 3) {
            alert.buttons.firstMatch.tap()
        }
        
        // Verify we're on the Explore tab
        let exploreTab = app.tabBars.buttons.element(boundBy: 0) // Assuming Explore is the second tab
        XCTAssertTrue(exploreTab.waitForExistence(timeout: 15), "Tab bar should appear after successful sign up")
    
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
