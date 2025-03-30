import Foundation
import Network

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)
    case unexpectedError
    case unauthorized
}

/// AppError defines all possible error types in the application
enum AppError: Error {
    // Network related errors
    case networkConnection
    case serverTimeout
    case serverError(Int, String?)
    case invalidResponse
    case apiLimitExceeded
    
    // Authentication errors
    case unauthorized
    case sessionExpired
    case invalidCredentials
    
    // Data errors
    case invalidData
    case dataNotFound
    case parsingError
    case cacheMiss
    
    // Input validation errors
    case invalidInput(String)
    case missingRequiredField(String)
    case invalidFormat(String)
    
    // Business logic errors
    case operationFailed(String)
    case resourceUnavailable
    case permissionDenied
    
    // System errors
    case internalError
    case fileSystemError
    case unsupportedOperation
    
    // Custom error with message
    case custom(String)
    
    // Map from APIError to AppError
    static func from(_ apiError: APIError) -> AppError {
        switch apiError {
        case .invalidURL:
            return .invalidInput("Invalid URL format")
        case .networkError(let error):
            if let nsError = error as NSError? {
                if nsError.domain == NSURLErrorDomain {
                    switch nsError.code {
                    case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                        return .networkConnection
                    case NSURLErrorTimedOut:
                        return .serverTimeout
                    default:
                        return .networkConnection
                    }
                }
            }
            return .networkConnection
        case .invalidResponse:
            return .invalidResponse
        case .decodingError:
            return .parsingError
        case .serverError(let message):
            return .serverError(500, message)
        case .unexpectedError:
            return .internalError
        case .unauthorized:
            return .unauthorized
        }
    }
}

// MARK: - LocalizedError Extension
extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        // Network related errors
        case .networkConnection:
            return "No internet connection. Please check your network settings and try again."
        case .serverTimeout:
            return "The server is taking too long to respond. Please try again later."
        case .serverError(let code, let message):
            return message ?? "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "The server response was invalid. Please try again later."
        case .apiLimitExceeded:
            return "You've reached the maximum number of requests. Please try again later."
            
        // Authentication errors
        case .unauthorized:
            return "You are not authorized to perform this action. Please sign in again."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
            
        // Data errors
        case .invalidData:
            return "The data is invalid or corrupted."
        case .dataNotFound:
            return "The requested information could not be found."
        case .parsingError:
            return "There was a problem processing the data from the server."
        case .cacheMiss:
            return "The cached data is not available."
            
        // Input validation errors
        case .invalidInput(let field):
            return "Invalid input: \(field)"
        case .missingRequiredField(let field):
            return "\(field) is required."
        case .invalidFormat(let message):
            return message
            
        // Business logic errors
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        case .resourceUnavailable:
            return "This resource is currently unavailable."
        case .permissionDenied:
            return "You don't have permission to access this resource."
            
        // System errors
        case .internalError:
            return "An internal error occurred. Please try again later."
        case .fileSystemError:
            return "Could not access the file system."
        case .unsupportedOperation:
            return "This operation is not supported."
            
        // Custom error
        case .custom(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkConnection:
            return "Check your internet connection and try again."
        case .serverTimeout:
            return "The server might be experiencing high traffic. Try again in a few minutes."
        case .sessionExpired, .unauthorized:
            return "Please sign in again to continue."
        case .invalidCredentials:
            return "Make sure you entered the correct email and password."
        case .serverError:
            return "Our team has been notified. Please try again later."
        default:
            return nil
        }
    }
}

/// ErrorHandlingService provides methods to handle errors consistently across the app
class ErrorHandlingService {
    static let shared = ErrorHandlingService()
    
    private init() {}
    
    // Network connectivity monitoring
    private let monitor = NWPathMonitor()
    private var isConnected = true
    
    // Start monitoring network connectivity
    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    // Stop monitoring network connectivity
    func stopNetworkMonitoring() {
        monitor.cancel()
    }
    
    // Check if device has internet connection
    func hasInternetConnection() -> Bool {
        return isConnected
    }
    
    // Handle errors and return user-friendly message
    func handle(_ error: Error) -> String {
        // Log the error
        print("❌ Error: \(error.localizedDescription)")
        
        // Convert to AppError if needed
        let appError: AppError
        
        if let apiError = error as? APIError {
            appError = AppError.from(apiError)
        } else if let appErr = error as? AppError {
            appError = appErr
        } else {
            // For other error types, create a generic error
            appError = .custom(error.localizedDescription)
        }
        
        // Handle specific error types
        switch appError {
        case .unauthorized, .sessionExpired:
            // Log out the user if their session is expired
            DispatchQueue.main.async {
                self.logoutIfNeeded()
            }
        case .networkConnection:
            // If we already know there's no connection, provide that information
            if !hasInternetConnection() {
                return "You're offline. Please check your internet connection and try again."
            }
        default:
            break
        }
        
        // Return user-friendly error message
        return appError.localizedDescription
    }
    
    // Log out user when their session is expired
    private func logoutIfNeeded() {
        // Check if we're already authenticated
        if KeychainManager.shared.hasValue(for: KeychainManager.Keys.authToken) {
            // Clear authentication state
            try? KeychainManager.shared.delete(key: KeychainManager.Keys.authToken)
            
            // Post notification for other parts of the app to respond
            NotificationCenter.default.post(name: Notification.Name("UserSessionExpired"), object: nil)
        }
    }
} 
