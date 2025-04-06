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
    
    func testBasicUserJourney() {
        // 1. Sign in with valid credentials
        XCTAssertTrue(testHelper.signIn(
            email: TestConfig.shared.testUser.email,
            password: TestConfig.shared.testUser.password
        ), "Should be able to sign in")
        
        // 2. Navigate to Categories tab (adjust index if needed)
        let categoriesTabIndex = 1 // Change this if your tab order is different
        let categoriesTab = app.tabBars.buttons.element(boundBy: categoriesTabIndex)
        categoriesTab.tap()
        
        // 3. Verify categories screen - adjust identifier if needed
        let categoryList = app.collectionViews.firstMatch
        // Alternative identifier options:
        // let categoryList = app.collectionViews["categoriesCollectionView"]
        // let categoryList = app.collectionViews.element(boundBy: 0)
        XCTAssertTrue(testHelper.waitForElement(categoryList), "Category collection view should be visible")
        
        // 4. Select a category if any exist
        if categoryList.cells.count > 0 {
            let firstCategory = categoryList.cells.element(boundBy: 0)
            firstCategory.tap()
            
            // Verify category detail screen appears
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            XCTAssertTrue(testHelper.waitForElement(backButton), "Back button should appear on category detail screen")
            
            // Go back to categories list
            backButton.tap()
        }
        
        // 5. Navigate to Profile tab (adjust index if needed)
        let profileTabIndex = 3 // Change this if your tab order is different
        let profileTab = app.tabBars.buttons.element(boundBy: profileTabIndex)
        profileTab.tap()
        
        // Verify profile screen appears - adjust identifier if needed
        // Try multiple possible identifiers for profile header
        let profileHeaderExists = app.staticTexts["profileHeaderTitle"].exists || 
                                 app.staticTexts["profileHeader"].exists ||
                                 app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Profile'")).element.exists
        
        XCTAssertTrue(profileHeaderExists, "Profile header should be visible")
    }
    
    func testComprehensiveUserFlow() {
        // Generate unique test data
        let timestamp = Int(Date().timeIntervalSince1970)
        let testEmail = "test\(timestamp)@example.com"
        let testPassword = "Test123!"
        let testUsername = "testuser\(timestamp)"
        let testFullName = "Test User \(timestamp)"
        
        // 1. Register a new user
        XCTAssertTrue(
            testHelper.registerNewUser(
                email: testEmail,
                password: testPassword,
                username: testUsername,
                fullName: testFullName
            ),
            "User registration should succeed"
        )
        
        // 2. Navigate to settings and sign out (adjust index if needed)
        let settingsTabIndex = 3 // Change this if your tab order is different
        let settingsTab = app.tabBars.buttons.element(boundBy: settingsTabIndex)
        settingsTab.tap()
        
        // Look for sign out button with multiple possible identifiers
        let signOutButton = app.buttons["signOutButton"].exists ? app.buttons["signOutButton"] :
                          app.buttons["logoutButton"].exists ? app.buttons["logoutButton"] :
                          app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign Out' OR label CONTAINS 'Log Out'")).element
        
        XCTAssertTrue(testHelper.waitForElement(signOutButton), "Sign out button should be visible")
        signOutButton.tap()
        
        // Confirm sign out if a confirmation dialog appears
        if app.alerts.buttons["Sign Out"].exists {
            app.alerts.buttons["Sign Out"].tap()
        } else if app.alerts.buttons["Log Out"].exists {
            app.alerts.buttons["Log Out"].tap()
        } else if app.alerts.buttons["OK"].exists {
            app.alerts.buttons["OK"].tap()
        } else if app.alerts.buttons["Yes"].exists {
            app.alerts.buttons["Yes"].tap()
        }
        
        // 3. Verify we're back at the sign in screen
        XCTAssertTrue(testHelper.isOnSignInScreen(), "Should be back on sign in screen")
        
        // 4. Sign in with the newly created credentials
        XCTAssertTrue(
            testHelper.signIn(
                email: testEmail,
                password: testPassword
            ),
            "Should be able to sign in with newly created account"
        )
        
        // 5. Verify we're logged in (tab bar is visible)
        XCTAssertTrue(testHelper.isLoggedIn(), "Should be logged in with newly created account")
    }
} 