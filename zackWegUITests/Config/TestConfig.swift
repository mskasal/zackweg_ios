import Foundation
import XCTest

struct TestUser {
    let email: String
    let password: String
    let username: String
    let fullName: String
}

/// TestConfig provides configuration values for tests.
/// This allows tests to be run against different environments.
class TestConfig {
    // Singleton instance
    static let shared = TestConfig()
    
    // Testing environment
    enum Environment: String {
        case dev = "Development"
        case staging = "Staging"
        case prod = "Production"
        
        var baseURL: String {
            switch self {
            case .dev:
                return "https://dev.zackweg.com"
            case .staging:
                return "https://staging.zackweg.com"
            case .prod:
                return "https://zackweg.com"
            }
        }
    }
    
    // Default environment for tests
    var environment: Environment = .dev
    
    // Test user for E2E testing
    let testUser: TestUser
    
    // Wait time for async operations
    var defaultTimeout: TimeInterval = 5.0
    
    private init() {
        // Configure test user for UI testing
        testUser = TestUser(
            email: "test@example.com",
            password: "Test123!",
            username: "testuser",
            fullName: "Test User"
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
        
        // Default to dev environment
        return .dev
    }
} 