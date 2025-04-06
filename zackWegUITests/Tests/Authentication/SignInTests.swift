import XCTest
@testable import zackWeg

class SignInTests: XCTestCase {
    var app: XCUIApplication!
    var testHelper: UITestHelper!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        testHelper = UITestHelper(app: app)
        
        // Enable UI testing mode
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["UI_TEST_MODE": "1"]
    }
    
    override func tearDown() {
        app = nil
        testHelper = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testSuccessfulSignIn() {
        // Launch app
        app.launch()
        
        // Wait for app to be ready
        if !testHelper.isOnSignInScreen() {
            testHelper.navigateToSignIn()
        }
        
        // Verify we're on the sign in screen
        XCTAssertTrue(testHelper.isOnSignInScreen(), "Should be on sign in screen")
        
        // Enter credentials and sign in
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let signInButton = app.buttons["signInButton"]
        
        testHelper.enterText(TestConfig.shared.testUser.email, in: emailField)
        testHelper.enterText(TestConfig.shared.testUser.password, in: passwordField)
        signInButton.tap()
        
        // Wait for sign in to complete (tab bar appears)
        XCTAssertTrue(testHelper.waitForElement(app.tabBars.firstMatch), "Should see tab bar after sign in")
    }
    
    func testFailedSignIn() {
        // Launch app
        app.launch()
        
        // Wait for app to be ready
        if !testHelper.isOnSignInScreen() {
            testHelper.navigateToSignIn()
        }
        
        // Enter invalid credentials
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let signInButton = app.buttons["signInButton"]
        
        testHelper.enterText(TestConfig.shared.testUser.email, in: emailField)
        testHelper.enterText("wrong_password", in: passwordField)
        signInButton.tap()
        
        // Wait for error alert to appear
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(testHelper.waitForElement(errorAlert), "Error alert should appear with wrong credentials")
        
        // Dismiss the alert
        if app.alerts.buttons["OK"].exists {
            app.alerts.buttons["OK"].tap()
        }
        
        // We should still be on the sign in screen
        XCTAssertTrue(testHelper.isOnSignInScreen(), "Should remain on sign in screen after failed sign in")
    }
    
    func testEmailValidation() {
        // Launch app
        app.launch()
        
        // Wait for app to be ready
        if !testHelper.isOnSignInScreen() {
            testHelper.navigateToSignIn()
        }
        
        // Test invalid email format
        let emailField = app.textFields["emailTextField"]
        let signInButton = app.buttons["signInButton"]
        
        testHelper.enterText("invalid-email", in: emailField)
        signInButton.tap()
        
        // Should see validation error message
        let validationError = app.staticTexts["emailValidationError"]
        XCTAssertTrue(testHelper.waitForElement(validationError), "Email validation error should appear")
    }
} 