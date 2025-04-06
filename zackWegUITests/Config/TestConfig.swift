import Foundation
import XCTest
@testable import zackWeg

/// TestConfig provides configuration values for tests.
/// This allows tests to be run against different environments.
class TestConfig {
    // Singleton instance
    static let shared = TestConfig()
    
    // Testing environment
    enum Environment: String {
        case mock = "Mock"
        case dev = "Development"
        case staging = "Staging"
        
        var baseURL: String {
            switch self {
            case .mock:
                return "http://localhost:8080"
            case .dev:
                return "https://dev.zackweg.com"
            case .staging:
                return "https://staging.zackweg.com"
            }
        }
    }
    
    // Default environment for tests
    var environment: Environment = .mock
    
    // Test credentials - these should be loaded from environment variables or a secure source in CI
    struct TestCredentials {
        let email: String
        let password: String
        let postalCode: String
        let countryCode: String
        let nickName: String
    }
    
    // Test user credentials for authentication tests
    var testUser: TestCredentials {
        return TestCredentials(
            email: "test@example.com",
            password: "Password123!",
            postalCode: "10115",
            countryCode: "DEU",
            nickName: "TestUser"
        )
    }
    
    // Helper method to set up the environment for a test
    func setupTestEnvironment() -> Environment {
        // Read from environment variables or test plan configurations
        if let envName = ProcessInfo.processInfo.environment["TEST_ENVIRONMENT"] {
            if let env = Environment(rawValue: envName) {
                environment = env
                return env
            }
        }
        
        // Default to mock environment
        return .mock
    }
    
    // Wait time for async operations
    var defaultTimeout: TimeInterval = 5.0
} 
