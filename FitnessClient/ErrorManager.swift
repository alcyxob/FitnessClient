// ErrorManager.swift
import Foundation
import SwiftUI

// MARK: - App Error Types
enum AppError: Error, LocalizedError {
    // Network Errors
    case networkUnavailable
    case requestTimeout
    case serverUnavailable
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError(statusCode: Int, message: String?)
    
    // Data Errors
    case invalidData
    case decodingFailed
    case encodingFailed
    
    // Authentication Errors
    case authenticationFailed
    case tokenExpired
    case biometricAuthFailed
    case keychainError
    
    // Validation Errors
    case invalidInput(field: String)
    case missingRequiredField(field: String)
    
    // Business Logic Errors
    case exerciseNotFound
    case clientNotFound
    case workoutNotFound
    case assignmentNotFound
    
    // System Errors
    case cameraUnavailable
    case storageUnavailable
    case unknown(String) // Changed from Error to String for Equatable conformance
    
    var errorDescription: String? {
        switch self {
        // Network Errors
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .serverUnavailable:
            return "Server is temporarily unavailable. Please try again later."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError(let statusCode, let message):
            return message ?? "Server error (\(statusCode)). Please try again."
            
        // Data Errors
        case .invalidData:
            return "Invalid data received from server."
        case .decodingFailed:
            return "Failed to process server response."
        case .encodingFailed:
            return "Failed to prepare request data."
            
        // Authentication Errors
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        case .biometricAuthFailed:
            return "Biometric authentication failed. Please try again."
        case .keychainError:
            return "Failed to access secure storage."
            
        // Validation Errors
        case .invalidInput(let field):
            return "Invalid \(field). Please check your input."
        case .missingRequiredField(let field):
            return "\(field) is required."
            
        // Business Logic Errors
        case .exerciseNotFound:
            return "Exercise not found."
        case .clientNotFound:
            return "Client not found."
        case .workoutNotFound:
            return "Workout not found."
        case .assignmentNotFound:
            return "Assignment not found."
            
        // System Errors
        case .cameraUnavailable:
            return "Camera is not available."
        case .storageUnavailable:
            return "Storage is not available."
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .requestTimeout, .serverUnavailable, .rateLimited:
            return true
        case .serverError(let statusCode, _):
            return statusCode >= 500 // Server errors are retryable
        default:
            return false
        }
    }
    
    var requiresAuthentication: Bool {
        switch self {
        case .unauthorized, .tokenExpired, .authenticationFailed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Equatable Conformance
extension AppError: Equatable {
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        // Network Errors
        case (.networkUnavailable, .networkUnavailable),
             (.requestTimeout, .requestTimeout),
             (.serverUnavailable, .serverUnavailable),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.rateLimited, .rateLimited):
            return true
        case (.serverError(let lhsCode, let lhsMessage), .serverError(let rhsCode, let rhsMessage)):
            return lhsCode == rhsCode && lhsMessage == rhsMessage
            
        // Data Errors
        case (.invalidData, .invalidData),
             (.decodingFailed, .decodingFailed),
             (.encodingFailed, .encodingFailed):
            return true
            
        // Authentication Errors
        case (.authenticationFailed, .authenticationFailed),
             (.tokenExpired, .tokenExpired),
             (.biometricAuthFailed, .biometricAuthFailed),
             (.keychainError, .keychainError):
            return true
            
        // Validation Errors
        case (.invalidInput(let lhsField), .invalidInput(let rhsField)):
            return lhsField == rhsField
        case (.missingRequiredField(let lhsField), .missingRequiredField(let rhsField)):
            return lhsField == rhsField
            
        // Business Logic Errors
        case (.exerciseNotFound, .exerciseNotFound),
             (.clientNotFound, .clientNotFound),
             (.workoutNotFound, .workoutNotFound),
             (.assignmentNotFound, .assignmentNotFound):
            return true
            
        // System Errors
        case (.cameraUnavailable, .cameraUnavailable),
             (.storageUnavailable, .storageUnavailable):
            return true
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
            
        default:
            return false
        }
    }
}

// MARK: - Error State
struct ErrorState: Equatable {
    let error: AppError
    let timestamp: Date
    let context: String?
    let isRetryable: Bool
    
    init(error: AppError, context: String? = nil) {
        self.error = error
        self.timestamp = Date()
        self.context = context
        self.isRetryable = error.isRetryable
    }
}

// MARK: - Global Error Manager
@MainActor
class ErrorManager: ObservableObject {
    @Published var currentError: ErrorState?
    @Published var isShowingError = false
    
    private var errorHistory: [ErrorState] = []
    private let maxHistoryCount = 50
    
    // Singleton instance
    static let shared = ErrorManager()
    
    private init() {}
    
    // MARK: - Error Handling
    func handle(_ error: Error, context: String? = nil) {
        let appError = convertToAppError(error)
        let errorState = ErrorState(error: appError, context: context)
        
        // Add to history
        errorHistory.append(errorState)
        if errorHistory.count > maxHistoryCount {
            errorHistory.removeFirst()
        }
        
        // Set current error
        currentError = errorState
        isShowingError = true
        
        // Log error
        logError(errorState)
        
        // Handle special cases
        if appError.requiresAuthentication {
            handleAuthenticationError()
        }
    }
    
    func clearError() {
        currentError = nil
        isShowingError = false
    }
    
    // MARK: - Error Conversion
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        if let apiError = error as? APINetworkError {
            switch apiError {
            case .invalidURL:
                return .invalidData
            case .requestFailed(let underlyingError):
                return convertNetworkError(underlyingError)
            case .noData:
                return .invalidData
            case .decodingError:
                return .decodingFailed
            case .serverError(let statusCode, let message):
                return .serverError(statusCode: statusCode, message: message)
            case .unauthorized:
                return .unauthorized
            case .forbidden:
                return .forbidden
            case .unknown(let statusCode):
                return .serverError(statusCode: statusCode, message: nil)
            }
        }
        
        return .unknown(error.localizedDescription)
    }
    
    private func convertNetworkError(_ error: Error) -> AppError {
        let nsError = error as NSError
        
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .networkUnavailable
        case NSURLErrorTimedOut:
            return .requestTimeout
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return .serverUnavailable
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Special Error Handling
    private func handleAuthenticationError() {
        // Notify auth service to handle logout
        NotificationCenter.default.post(name: .authenticationRequired, object: nil)
    }
    
    // MARK: - Logging
    private func logError(_ errorState: ErrorState) {
        print("🚨 ERROR: \(errorState.error.localizedDescription ?? "Unknown error")")
        if let context = errorState.context {
            print("📍 Context: \(context)")
        }
        print("⏰ Timestamp: \(errorState.timestamp)")
        print("🔄 Retryable: \(errorState.isRetryable)")
    }
    
    // MARK: - Error History
    func getRecentErrors(limit: Int = 10) -> [ErrorState] {
        return Array(errorHistory.suffix(limit))
    }
    
    func clearHistory() {
        errorHistory.removeAll()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let authenticationRequired = Notification.Name("authenticationRequired")
}

// MARK: - Error View Modifier
struct ErrorHandlingModifier: ViewModifier {
    @StateObject private var errorManager = ErrorManager.shared
    @State private var showRetryButton = false
    
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorManager.isShowingError) {
                if let currentError = errorManager.currentError, currentError.isRetryable {
                    Button("Retry") {
                        onRetry?()
                        errorManager.clearError()
                    }
                }
                Button("OK") {
                    errorManager.clearError()
                }
            } message: {
                if let currentError = errorManager.currentError {
                    Text(currentError.error.localizedDescription ?? "An unknown error occurred")
                }
            }
    }
}

// MARK: - View Extension
extension View {
    func errorHandling(onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorHandlingModifier(onRetry: onRetry))
    }
}
