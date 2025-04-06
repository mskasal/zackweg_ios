# Zack Weg iOS Testing

This document provides an overview of the testing approach, structure, and guidelines for the Zack Weg iOS application.

## Testing Structure

The testing suite is organized into the following directories:

```
Testing/
├── Config/              # Test configuration and environment settings
├── Mocks/               # Mock implementations of services and dependencies
├── Tests/               # Test cases
│   ├── Authentication/  # Authentication-related tests
│   ├── E2E/             # End-to-end user journey tests
│   └── UI/              # UI tests for specific screens
└── Utils/               # Test helpers and utilities
```

## Test Categories

### Unit Tests

Unit tests verify individual components in isolation. These tests are fast and should not rely on external systems.

Key areas covered:
- ViewModels
- Services
- Utilities
- Extensions

### UI Tests

UI tests verify that UI components work as expected and user interactions function correctly.

Key areas covered:
- Screen navigation
- Form validation
- UI components display correctly
- Accessibility

### Integration Tests

Integration tests verify that components work correctly together. 

Key areas covered:
- ViewModels with Services
- Services with each other

### End-to-End Tests

E2E tests verify complete user journeys through the application.

Key areas covered:
- User authentication flow
- Creating and viewing content
- User settings management

## Running Tests

### Using Xcode

1. Open the project in Xcode
2. Select the `DevelopmentTestPlan` from the scheme selector
3. Choose the desired configuration (Mock or Development)
4. Run tests using `⌘U` or navigate to Product > Test

### Using Command Line

```bash
# Run all tests
xcodebuild test -project zack_weg_ios.xcodeproj -scheme zack_weg_ios -testPlan DevelopmentTestPlan -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

# Run specific test class
xcodebuild test -project zack_weg_ios.xcodeproj -scheme zack_weg_ios -testPlan DevelopmentTestPlan -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' -only-testing:zack_weg_iosTests/SignInTests
```

## Testing Environments

The testing framework supports multiple environments:

1. **Mock** - Uses mock implementations of services for isolated testing
2. **Development** - Uses the development API for more realistic testing
3. **Staging** - Uses the staging API for pre-production testing

Configure the environment in the test plan or by setting the `TEST_ENVIRONMENT` environment variable.

## Mocking

The project uses a service-based architecture that facilitates testing through dependency injection:

1. Services are defined with protocols
2. Mock implementations can be created for testing
3. Dependency injection allows swapping real implementations with mocks

Example of mocking the API service:

```swift
// Create a mock API service
let mockApiService = MockAPIService()
mockApiService.shouldSucceed = true

// Inject the mock into a view model for testing
let viewModel = AuthViewModel(apiService: mockApiService)
```

## Best Practices

1. **Test Organization**:
   - Use descriptive test names following "test[WhatIsTested]"
   - Group tests logically into test classes
   - Keep tests independent of each other

2. **Test Coverage**:
   - Aim for high test coverage, especially for critical paths
   - Focus on testing business logic rather than UI details
   - Include both happy path and error cases

3. **UI Testing**:
   - Add accessibility identifiers to UI elements
   - Use the UI test helper utilities
   - Minimize brittleness by using robust selectors

4. **Handling Asynchronous Code**:
   - Use async/await for testing asynchronous operations
   - Set appropriate timeouts for network operations

5. **Test Data Management**:
   - Use fixed test data from the TestConfig class
   - Reset app state between tests as needed

## Adding New Tests

When adding new tests:

1. Identify what feature needs testing
2. Determine the appropriate test level (unit, integration, UI)
3. Create a new test file in the appropriate directory
4. Follow the existing patterns for setUp and tearDown
5. Implement test cases using Given-When-Then structure
6. Update the test plan if needed

## Continuous Integration

Tests are executed automatically on CI during pull requests and before releases.

- The development test plan runs on all PRs
- Full test suites (including UI tests) run before releases
- Test failures block merges to main branch

## Updating Test Plans

If you need to modify the test plan:

1. Open the test plan file in Xcode
2. Make desired changes to configurations, targets, etc.
3. Commit the changes to the repository

## Troubleshooting

Common issues and solutions:

- **Tests fail inconsistently**: Check for timeouts or race conditions
- **UI tests can't find elements**: Verify accessibility identifiers
- **Network-related failures**: Ensure mock services are correctly configured
- **Keychain errors**: Reset simulator between test runs 