import XCTest
@testable import zackWeg

class UserJourneyTests: XCTestCase {
    var app: XCUIApplication!
    var testHelper: UITestHelper!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        testHelper = UITestHelper(app: app)
        
        // Enable UI testing mode but don't reset data to test with real account
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["UI_TEST_MODE": "1"]
    }
    
    override func tearDown() {
        app = nil
        testHelper = nil
        super.tearDown()
    }
    
    func testCompleteUserJourney() {
        // Launch app
        app.launch()
        
        // Accept splash screen if it appears
        let splashScreen = app.otherElements["splashScreen"]
        if splashScreen.exists {
            // Wait for splash screen to dismiss itself or tap to dismiss if needed
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: splashScreen
            )
            XCTWaiter.wait(for: [expectation], timeout: 5.0)
        }
        
        // STEP 1: SIGN IN
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
        
        // Wait for sign in to complete
        XCTAssertTrue(testHelper.waitForElement(app.tabBars.firstMatch), "Should see tab bar after sign in")
        
        // STEP 2: EXPLORE TAB - BROWSE ITEMS
        app.tabBars.buttons.element(boundBy: 0).tap() // Explore tab
        
        // Wait for explore view to load
        let searchField = app.searchFields["exploreSearchField"]
        XCTAssertTrue(testHelper.waitForElement(searchField), "Search field should be visible")
        
        // Tap a category
        let firstCategory = app.buttons.matching(identifier: "categoryButton").firstMatch
        if firstCategory.exists {
            firstCategory.tap()
            
            // Wait for items to load
            let firstItem = app.cells.matching(identifier: "postCell").firstMatch
            XCTAssertTrue(testHelper.waitForElement(firstItem), "Should see items after tapping category")
            
            // Tap on an item
            firstItem.tap()
            
            // Wait for item details to load
            let backButton = app.buttons["backButton"]
            XCTAssertTrue(testHelper.waitForElement(backButton), "Back button should be visible on item details")
            
            // Go back to items list
            backButton.tap()
        }
        
        // STEP 3: CREATE A POST
        app.tabBars.buttons.element(boundBy: 1).tap() // Create post tab
        
        // Wait for create post view to load
        let titleField = app.textFields["postTitleField"]
        XCTAssertTrue(testHelper.waitForElement(titleField), "Title field should be visible")
        
        // Fill post details
        testHelper.enterText("E2E Test Item", in: titleField)
        
        let descriptionField = app.textViews["postDescriptionField"]
        testHelper.enterText("This is a test item description created by automated E2E UI tests.", in: descriptionField)
        
        // Select a category
        app.buttons["selectCategoryButton"].tap()
        let firstCategoryInPicker = app.buttons.matching(identifier: "categoryPickerItem").firstMatch
        if firstCategoryInPicker.exists {
            firstCategoryInPicker.tap()
        }
        
        // Upload an image if possible, or skip
        let addImageButton = app.buttons["addImageButton"]
        if addImageButton.exists && addImageButton.isEnabled {
            addImageButton.tap()
            
            // Handle the photo picker if it appears
            if app.sheets["Photo Picker"].exists {
                // Select first photo
                let firstPhoto = app.images.firstMatch
                if firstPhoto.exists {
                    firstPhoto.tap()
                } else {
                    // Dismiss picker if no photos
                    app.buttons["Cancel"].tap()
                }
            }
        }
        
        // Submit post
        app.buttons["createPostButton"].tap()
        
        // Wait for success confirmation
        let successAlert = app.alerts.firstMatch
        XCTAssertTrue(testHelper.waitForElement(successAlert), "Success alert should appear")
        app.alerts.buttons["OK"].tap()
        
        // STEP 4: CHECK PROFILE/SETTINGS
        app.tabBars.buttons.element(boundBy: 3).tap() // Profile tab
        
        // Verify profile screen elements
        let nickNameLabel = app.staticTexts.matching(identifier: "userNickNameLabel").firstMatch
        XCTAssertTrue(testHelper.waitForElement(nickNameLabel), "Nick name should be visible on profile")
        
        // STEP 5: SIGN OUT
        let signOutButton = app.buttons["signOutButton"]
        XCTAssertTrue(testHelper.waitForElement(signOutButton), "Sign out button should be visible")
        signOutButton.tap()
        
        // Confirm sign out if a confirmation appears
        if app.alerts.buttons["Sign Out"].exists {
            app.alerts.buttons["Sign Out"].tap()
        }
        
        // Verify we're back at sign in screen
        XCTAssertTrue(testHelper.waitForElement(app.textFields["emailTextField"]), "Should return to sign in screen after sign out")
    }
} 