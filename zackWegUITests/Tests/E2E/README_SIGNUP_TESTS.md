# Sign Up Tests Guide

This guide explains how to run and understand the Sign Up tests for the Zack Weg iOS app.

## Test Overview

The `SignUpTests.swift` file contains the following test case:

- **testSignUpWithSpecificData**: Tests signing up with specific test data and verifies the user is successfully registered and navigated to the Explore view.

## Test Data

The test uses the following specific test data:

- **Email**: samed_test_1@zackweg.com
- **Nickname**: samed_test_1
- **Full Name**: Test User
- **Password**: 123123123
- **Postal Code**: 10317

## Running the Tests

To run the Sign Up tests:

1. Open the project in Xcode
2. Select the `DevelopmentTestPlan` from the scheme selector
3. Select one of these options:
   - Run all tests using ⌘U
   - Run specific test by navigating to the Test Navigator (⌘6), right-clicking on `SignUpTests` and selecting "Run SignUpTests"

Alternatively, you can run the tests from the command line:

```bash
xcodebuild test -project zack_weg_ios.xcodeproj -scheme zack_weg_ios -testPlan DevelopmentTestPlan -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' -only-testing:ZackWegUITests/SignUpTests
```

## How the Test Works

1. The test launches the app with `--uitesting` and `--reset-state` flags
2. It waits for the splash screen to complete
3. It navigates to the Sign Up screen
4. It fills in the registration form with the specified test data
5. It submits the form and handles any confirmation alerts
6. It verifies successful registration by checking if we're taken to the Explore view
7. It verifies the search field exists on the Explore view

## Handling Form Variations

The test is designed to be robust against different form implementations:

- It handles different accessibility identifier variations
- It accommodates both with and without confirm password fields
- It checks for and handles the postal code field if present

## Troubleshooting

If tests fail, check for these common issues:

1. **App Reset**: Ensure the app properly resets user state between test runs
2. **Form Fields**: If fields can't be found, check the identifiers in the app code
3. **Navigation Issues**: Verify tab bar indices are correctly configured
4. **Alert Handling**: If alerts aren't processed, check that confirm button text matches the expected values

## Notes

- The test creates a new user account each time it runs, so be aware that it could create many test accounts in your test environment
- This test requires the app to be in a state where new registrations are accepted
- If running against a production environment, be sure to clean up test accounts afterward 