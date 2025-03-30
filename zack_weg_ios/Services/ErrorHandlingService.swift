import Foundation
import Network

// Import needed for String.localized extension
import SwiftUI  // This should pull in LanguageManager via SwiftUI imports

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
            return "error.network.connection".localized
        case .serverTimeout:
            return "error.network.timeout".localized
        case .serverError(let code, let message):
            if let message = message, !message.isEmpty {
                return String(format: "error.server.with_message".localized, message)
            }
            return String(format: "error.server.with_code".localized, code)
        case .invalidResponse:
            return "error.response.invalid".localized
        case .apiLimitExceeded:
            return "error.api.limit_exceeded".localized
            
        // Authentication errors
        case .unauthorized:
            return "error.auth.unauthorized".localized
        case .sessionExpired:
            return "error.auth.session_expired".localized
        case .invalidCredentials:
            return "error.auth.invalid_credentials".localized
            
        // Data errors
        case .invalidData:
            return "error.data.invalid".localized
        case .dataNotFound:
            return "error.data.not_found".localized
        case .parsingError:
            return "error.data.parsing".localized
        case .cacheMiss:
            return "error.data.cache_miss".localized
            
        // Input validation errors
        case .invalidInput(let field):
            return String(format: "error.input.invalid".localized, field)
        case .missingRequiredField(let field):
            return String(format: "error.input.missing_field".localized, field)
        case .invalidFormat(let message):
            return String(format: "error.input.invalid_format".localized, message)
            
        // Business logic errors
        case .operationFailed(let reason):
            return String(format: "error.operation.failed".localized, reason)
        case .resourceUnavailable:
            return "error.resource.unavailable".localized
        case .permissionDenied:
            return "error.permission.denied".localized
            
        // System errors
        case .internalError:
            return "error.system.internal".localized
        case .fileSystemError:
            return "error.system.file".localized
        case .unsupportedOperation:
            return "error.system.unsupported".localized
            
        // Custom error
        case .custom(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkConnection:
            return "error.recovery.network".localized
        case .serverTimeout:
            return "error.recovery.server_timeout".localized
        case .sessionExpired, .unauthorized:
            return "error.recovery.auth".localized
        case .invalidCredentials:
            return "error.recovery.credentials".localized
        case .serverError:
            return "error.recovery.server".localized
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
