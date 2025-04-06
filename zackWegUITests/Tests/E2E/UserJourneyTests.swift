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
} 