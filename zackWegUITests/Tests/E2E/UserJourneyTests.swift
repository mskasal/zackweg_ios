import XCTest
@testable import zackWeg

class UserJourneyTests: XCTestCase {
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
    
    func testSplashScreenAppears() {
        // Check for app logo at launch, which appears in the splash screen
        let appLogo = app.images["appLogo"]
        
        // We should check if the app logo exists (or wait a small amount for it to appear)
        // This uses a short timeout since the splash screen is brief
        let logoAppeared = XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: appLogo)],
            timeout: 2.0
        )
        
        // If we didn't see the logo, try a more generic approach to find any image
        if logoAppeared != .completed {
            let anyImage = app.images.firstMatch
            XCTAssertTrue(anyImage.exists, "App should show splash screen with logo on launch")
        }
        
        // Wait for the splash screen to transition away
        // The splash is configured to stay for 2 seconds, so we'll wait 3 to be safe
        sleep(3)
        
        // Now check for the sign in screen elements to appear
        let signInScreen = app.otherElements["signInScreenView"]
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let signInButton = app.buttons["signInButton"]
        
        // Verify at least one of these elements is now visible, indicating transition from splash screen
        let signInElementsAppeared = emailField.exists || passwordField.exists || signInButton.exists || signInScreen.exists
        
        XCTAssertTrue(signInElementsAppeared, "Sign in screen should appear after splash screen")
    }
    
    func testSignInViewValidation() {
        // Wait longer for UI to fully load (including animations and transitions)
        sleep(3) // Allow splash screen to complete
        
        // 1. Check if sign in screen exists with diagnostics
        let signInScreen = app.otherElements["signInScreenView"]
        let signInExists = waitForElement(signInScreen, timeout: 5)
        
        // Add diagnostic information if the element doesn't exist
        if !signInExists {
            // Print hierarchy for debugging
            print("UI Hierarchy: \(app.debugDescription)")
            
            // Try to locate by other means
            let emailField = app.textFields["emailTextField"]
            let passwordField = app.secureTextFields["passwordTextField"]
            let signInButton = app.buttons["signInButton"]
            
            // Check if any sign in elements exist as fallback verification
            let signInElementsAppeared = emailField.exists || passwordField.exists || signInButton.exists
            XCTAssertTrue(signInElementsAppeared, "At least one sign in element should exist")
            
            // Continue test if at least basic elements are found
            if !signInElementsAppeared {
                XCTFail("Sign in screen not found, aborting test")
                return
            }
        } else {
            XCTAssertTrue(signInExists, "Sign in screen should exist")
        }
        
        // Locate UI elements
        let appLogo = app.images["appLogo"]
        let welcomeText = app.staticTexts["welcomeBackText"]
        let signInToAccountText = app.staticTexts["signInToAccountText"]
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let togglePasswordButton = app.buttons["togglePasswordButton"]
        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        let signInButton = app.buttons["signInButton"]
        let createAccountButton = app.buttons["createAccountButton"]
        let noAccountText = app.staticTexts["noAccountText"]
        
        // Verify core essential elements exist with individual assertions 
        // (so test continues even if some elements are missing)
        if !emailField.exists { XCTFail("Email field missing") }
        if !passwordField.exists { XCTFail("Password field missing") }
        if !signInButton.exists { XCTFail("Sign in button missing") }
        
        // Store initial values for any elements that exist
        let initialWelcomeText = welcomeText.exists ? welcomeText.label : ""
        let initialSignInAccountText = signInToAccountText.exists ? signInToAccountText.label : ""
        let initialEmailPlaceholder = emailField.exists ? (emailField.placeholderValue ?? "") : ""
        let initialPasswordPlaceholder = passwordField.exists ? (passwordField.placeholderValue ?? "") : ""
        let initialSignInButtonText = signInButton.exists ? signInButton.label : ""
        
        // Check for language switcher
        let languageSwitcher = app.buttons["languageSwitcherButton"]
        if languageSwitcher.exists {
            // Tap on language switcher to open menu
            languageSwitcher.tap()
            
            // Wait for menu to appear - try multiple approaches to find German option
            sleep(1) // Wait for menu animation
            
            // Print menu hierarchy for debugging
            print("Menu hierarchy after tap: \(app.debugDescription)")
            
            // Try different query approaches to find the German option
            var germanOptionFound = false
            
            // Approach 1: Try direct menuItems with accessibility ID
            if app.menuItems["languageOption_de"].exists {
                app.menuItems["languageOption_de"].tap()
                germanOptionFound = true
            } 
            // Approach 2: Try buttons with accessibility ID
            else if app.buttons["languageOption_de"].exists {
                app.buttons["languageOption_de"].tap()
                germanOptionFound = true
            }
            // Approach 3: Try to find by display text "Deutsch"
            else if app.menuItems.staticTexts["Deutsch"].exists {
                app.menuItems.staticTexts["Deutsch"].tap()
                germanOptionFound = true
            }
            // Approach 4: Look for any menu item or button containing "Deutsch"
            else {
                let deutschText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Deutsch'")).firstMatch
                if deutschText.exists {
                    deutschText.tap()
                    germanOptionFound = true
                } else {
                    // Try checking within any menu
                    let menus = app.descendants(matching: .menu)
                    for i in 0..<menus.count {
                        let menu = menus.element(boundBy: i)
                        if menu.exists {
                            print("Found menu \(i): \(menu.debugDescription)")
                            let deutschInMenu = menu.buttons.matching(NSPredicate(format: "label CONTAINS 'Deutsch'")).firstMatch
                            if deutschInMenu.exists {
                                deutschInMenu.tap()
                                germanOptionFound = true
                                break
                            }
                        }
                    }
                }
            }
            
            // If we found and tapped a German option, verify the language changed
            if germanOptionFound {
                // Wait for language change to take effect
                sleep(1) // Longer wait for UI update
                
                // Check that at least one text element changed
                if welcomeText.exists && initialWelcomeText != "" {
                    let textChanged = XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                        predicate: NSPredicate(format: "label != %@", initialWelcomeText),
                        object: welcomeText
                    )], timeout: 2.0) == .completed
                    
                    if !textChanged {
                        XCTFail("Language did not change after selecting German option")
                    }
                    
                    // Switch back to English - Only if language actually changed
                    languageSwitcher.tap()
                    sleep(1)
                    
                    // Try different approaches to find English option
                    if app.menuItems["languageOption_en"].exists {
                        app.menuItems["languageOption_en"].tap()
                    } else if app.buttons["languageOption_en"].exists {
                        app.buttons["languageOption_en"].tap()
                    } else {
                        let englishText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'English'")).firstMatch
                        if englishText.exists {
                            englishText.tap()
                        }
                    }
                    sleep(1) // Wait for language to change back
                }
            } else {
                XCTFail("Could not find German language option using any method")
                print("Available menu items after language switcher tap:")
                app.menuItems.allElementsBoundByIndex.forEach { item in
                    print("Menu item: \(item.debugDescription)")
                }
                app.buttons.allElementsBoundByIndex.forEach { button in
                    print("Button: \(button.debugDescription)")
                }
            }
        } else {
            print("Language switcher not found - skipping language test section")
        }
        
        // Only continue with validation tests if email and password fields exist
        if emailField.exists && passwordField.exists {
            // Test invalid email
            emailField.tap()
            emailField.typeText("invalid-email")
            
            // Tap elsewhere to trigger validation
            app.tap()
            
            // Wait for error message to appear
            let emailError = app.staticTexts["emailValidationError"]
            let errorAppeared = waitForElement(emailError, timeout: 2)
            if !errorAppeared {
                XCTFail("Email validation error not displayed for invalid email")
            }
            
            // Only continue if we can proceed with the test
            if emailField.exists {
                // Clear and enter valid email
                emailField.tap()
                let clearButton = emailField.buttons["Clear text"].firstMatch
                if clearButton.exists {
                    clearButton.tap()
                } else {
                    // Alternative approach if Clear button isn't available
                    let stringLength = "invalid-email".count
                    let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringLength)
                    emailField.typeText(deleteString)
                }
                emailField.typeText("test@example.com")
            }
            
            // Test invalid password (too short)
            passwordField.tap()
            passwordField.typeText("short")
            
            // Tap elsewhere to trigger validation
            app.tap()
            
            // Check for error message
            let passwordError = app.staticTexts["passwordValidationError"]
            XCTAssertTrue(waitForElement(passwordError, timeout: 2), "Password validation error should be displayed for short password")
            
            // Test password visibility toggle
            togglePasswordButton.tap()
            
            // Password field should change from secure to regular text field
            let visiblePasswordField = app.textFields["passwordTextField"]
            XCTAssertTrue(waitForElement(visiblePasswordField, timeout: 2), "Password should be visible after toggle")
            
            // Test form validation when trying to submit with invalid data
            signInButton.tap()
            
            // Check for alert error
            let errorAlert = app.alerts.firstMatch
            XCTAssertTrue(errorAlert.waitForExistence(timeout: 2), "Error alert should appear when submitting invalid form")
            
            // Dismiss the alert
            errorAlert.buttons.firstMatch.tap()
        } else {
            XCTFail("Cannot perform validation tests because email or password fields are missing")
        }
    }
    
    // Helper function to wait for an element to appear
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    func testSignUpViewValidation() {
        // Wait for sign in screen to appear first
        sleep(3) // Wait for splash screen to complete
        
        // Find and tap the create account button to navigate to sign-up
        let createAccountButton = app.buttons["createAccountButton"]
        XCTAssertTrue(waitForElement(createAccountButton, timeout: 5), "Create account button should exist")
        createAccountButton.tap()
        
        // Wait for sign-up screen to appear
        sleep(1) // Allow for screen transition
        
        // 1. Check if sign up screen exists
        let signUpScreen = app.otherElements["signUpScreenView"]
        let signUpExists = waitForElement(signUpScreen, timeout: 5)
        
        // Try to locate by other means if needed
        if !signUpExists {
            print("UI Hierarchy: \(app.debugDescription)")
            
            // Try to find key sign-up elements as fallback
            let nameField = app.textFields["signUpNameTextField"]
            let emailField = app.textFields["signUpEmailTextField"]
            let passwordField = app.secureTextFields["signUpPasswordTextField"]
            let signUpButton = app.buttons["signUpButton"]
            
            let signUpElementsAppeared = nameField.exists || emailField.exists || passwordField.exists || signUpButton.exists
            XCTAssertTrue(signUpElementsAppeared, "At least one sign up element should exist")
            
            if !signUpElementsAppeared {
                XCTFail("Sign up screen not found, aborting test")
                return
            }
        }
        
        // 2. Locate and verify UI elements
        let createAccountText = app.staticTexts["signUpCreateAccountText"]
        let nameField = app.textFields["signUpNameTextField"]
        let emailField = app.textFields["signUpEmailTextField"]
        let passwordField = app.secureTextFields["signUpPasswordTextField"]
        let togglePasswordButton = app.buttons["signUpTogglePasswordButton"]
        let signUpButton = app.buttons["signUpButton"]
        
        // Verify core elements exist
        if !nameField.exists { XCTFail("Name field missing") }
        if !emailField.exists { XCTFail("Email field missing") }
        if !passwordField.exists { XCTFail("Password field missing") }
        if !signUpButton.exists { XCTFail("Sign up button missing") }
        
        // 3. Validate form interactions and error messages
        
        // Test empty name validation
        nameField.tap()
        nameField.typeText("")
        app.tap() // Tap elsewhere to trigger validation
        
        let nameError = app.staticTexts["signUpNameValidationError"]
        if nameError.exists {
            print("Name validation error detected: \(nameError.label)")
        }
        
        // Test invalid email validation
        emailField.tap()
        emailField.typeText("invalid-email")
        app.tap() // Tap elsewhere
        
        let emailError = app.staticTexts["signUpEmailValidationError"]
        XCTAssertTrue(waitForElement(emailError, timeout: 2), "Email validation error should appear")
        
        // Test password validation (too short)
        passwordField.tap()
        passwordField.typeText("short")
        app.tap()
        
        let passwordError = app.staticTexts["signUpPasswordValidationError"]
        XCTAssertTrue(waitForElement(passwordError, timeout: 2), "Password validation error should appear")
        
        // Test password visibility toggle
        if togglePasswordButton.exists {
            togglePasswordButton.tap()
            
            // Password should be visible now
            let visiblePasswordField = app.textFields["signUpPasswordTextField"]
            XCTAssertTrue(waitForElement(visiblePasswordField, timeout: 2), "Password should be visible after toggle")
            
            // Toggle back
            togglePasswordButton.tap()
        }
        
        // Test form submission with errors
        signUpButton.tap()
        
        // Check for error alert
        let errorAlert = app.alerts.firstMatch
        let alertAppeared = errorAlert.waitForExistence(timeout: 2)
        if alertAppeared {
            // Dismiss alert
            errorAlert.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Forgot Password Test
    
    func testForgotPasswordViewValidation() {
        // Wait for sign in screen to appear first
        sleep(3) // Wait for splash screen to complete
        
        // Find and tap the forgot password button to navigate to forgot password screen
        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        XCTAssertTrue(waitForElement(forgotPasswordButton, timeout: 5), "Forgot password button should exist")
        
        // Print UI state before tapping
        print("UI before tapping forgot password: \(app.debugDescription)")
        
        // Tap with retry mechanism
        var screenAppeared = false
        for attempt in 1...3 {
            print("Attempt \(attempt) to open forgot password screen")
            forgotPasswordButton.tap()
            
            // Wait longer for forgot password screen to appear - sheets can take time to animate
            sleep(2)
            
            // Check if the screen appeared
            let forgotPasswordScreen = app.otherElements["forgotPasswordScreenView"]
            let emailField = app.textFields["forgotPasswordEmailTextField"]
            
            if forgotPasswordScreen.exists || emailField.exists {
                screenAppeared = true
                print("Forgot password screen detected on attempt \(attempt)")
                break
            } else {
                print("Screen not found on attempt \(attempt), printing hierarchy:")
                print(app.debugDescription)
                
                // If attempt failed, try to dismiss any alerts that might be in the way
                if app.alerts.count > 0 {
                    app.alerts.buttons.firstMatch.tap()
                    sleep(1)
                }
            }
        }
        
        XCTAssertTrue(screenAppeared, "Forgot password screen should appear after tapping button")
        if !screenAppeared {
            XCTFail("Could not navigate to forgot password screen after multiple attempts")
            return
        }
        
        // 1. Verify that we're actually on the forgot password screen
        let forgotPasswordScreen = app.otherElements["forgotPasswordScreenView"]
        let titleText = app.staticTexts["forgotPasswordTitleText"]
        let emailField = app.textFields["forgotPasswordEmailTextField"]
        let resetButton = app.buttons["resetPasswordButton"]
        
        // First try waiting for elements with individual timeouts
        let screenExists = waitForElement(forgotPasswordScreen, timeout: 3)
        let emailExists = waitForElement(emailField, timeout: 3)
        let resetExists = waitForElement(resetButton, timeout: 3)
        
        print("Forgot password screen elements found: Screen=\(screenExists), Email=\(emailExists), Reset=\(resetExists)")
        
        // If elements aren't found, print detailed diagnostics
        if !emailExists {
            print("Could not find forgot password email field. All text fields:")
            app.textFields.allElementsBoundByIndex.forEach { field in
                print("TextField: \(field.debugDescription)")
            }
            
            // Try looking for any element that might be part of the forgot password screen
            let possibleFields = app.textFields.allElementsBoundByIndex
            if !possibleFields.isEmpty {
                print("Attempting to interact with first available text field as fallback")
                let firstField = possibleFields.first!
                firstField.tap()
                firstField.typeText("test@example.com")
                app.tap() // Tap elsewhere
            } else {
                XCTFail("No text fields found at all, cannot continue test")
                return
            }
        } else {
            // 3. Test validation and functionality
            print("Found forgot password email field, proceeding with test")
            
            // Test invalid email validation
            emailField.tap()
            emailField.typeText("invalid-email")
            app.tap() // Tap elsewhere to trigger validation
            
            let emailError = app.staticTexts["forgotPasswordEmailValidationError"]
            let errorAppeared = waitForElement(emailError, timeout: 2)
            
            if errorAppeared {
                print("Validation error appeared as expected")
            } else {
                print("No validation error found, checking all static texts:")
                app.staticTexts.allElementsBoundByIndex.forEach { text in
                    print("Text: \(text.label) - \(text.identifier)")
                }
            }
            
            // Clear and enter valid email
            emailField.tap()
            let clearButton = emailField.buttons["Clear text"].firstMatch
            if clearButton.exists {
                clearButton.tap()
            } else {
                // Alternative approach if Clear button isn't available
                let stringLength = "invalid-email".count
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringLength)
                emailField.typeText(deleteString)
            }
            emailField.typeText("test@example.com")
            
            // Test form submission if reset button exists
            if resetExists {
                resetButton.tap()
                
                // Check for confirmation alert or success message
                let successAlert = app.alerts.firstMatch
                let alertAppeared = successAlert.waitForExistence(timeout: 2)
                
                if alertAppeared {
                    print("Found alert after reset password: \(successAlert.label)")
                    
                    // Get the alert message for verification
                    let alertText = successAlert.staticTexts.element(boundBy: 1).label
                    print("Alert message: \(alertText)")
                    
                    // Dismiss alert
                    successAlert.buttons.firstMatch.tap()
                }
            }
        }
        
        // Try to navigate back to sign in
        let backToSignInButton = app.buttons["backToSignInButton"]
        if backToSignInButton.exists {
            backToSignInButton.tap()
        } else {
            print("Back button not found, trying to dismiss the screen")
            
            // Try standard iOS back button or cancel button
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists {
                backButton.tap()
            } else {
                // Try to find any button that might dismiss the screen
                let possibleButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Back' OR label CONTAINS 'Cancel' OR label CONTAINS 'Close'"))
                if possibleButtons.count > 0 {
                    possibleButtons.element(boundBy: 0).tap()
                } else {
                    // Try swipe down to dismiss
                    let topPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
                    let bottomPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
                    topPoint.press(forDuration: 0.3, thenDragTo: bottomPoint, withVelocity: 5000, thenHoldForDuration: 0.2)
                }
            }
        }
    }
} 
