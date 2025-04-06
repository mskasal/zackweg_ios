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
        // Verify splash screen shows briefly on app launch
        // Note: Make sure the splash screen has this accessibility identifier in your app
        let splashScreen = app.otherElements["splashScreen"]
        XCTAssertTrue(splashScreen.exists, "Splash screen should appear on launch")
        
        // Wait for splash screen to disappear
        let disappearExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: splashScreen
        )
        _ = XCTWaiter.wait(for: [disappearExpectation], timeout: 5.0)
    }
} 