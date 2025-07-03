// LoadingStateManager.swift
import Foundation
import SwiftUI

// MARK: - Loading State Types
enum LoadingState: Equatable {
    case idle
    case loading(message: String? = nil)
    case success
    case error(AppError)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var error: AppError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Async Operation Result
enum AsyncResult<T> {
    case loading
    case success(T)
    case failure(AppError)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
    
    var error: AppError? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Loading State Manager
@MainActor
class LoadingStateManager: ObservableObject {
    @Published private(set) var activeOperations: Set<String> = []
    @Published private(set) var operationStates: [String: LoadingState] = [:]
    
    var isAnyOperationLoading: Bool {
        !activeOperations.isEmpty
    }
    
    // MARK: - Operation Management
    func startOperation(_ operationId: String, message: String? = nil) {
        activeOperations.insert(operationId)
        operationStates[operationId] = .loading(message: message)
    }
    
    func completeOperation(_ operationId: String) {
        activeOperations.remove(operationId)
        operationStates[operationId] = .success
        
        // Clean up after a delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            operationStates.removeValue(forKey: operationId)
        }
    }
    
    func failOperation(_ operationId: String, error: AppError) {
        activeOperations.remove(operationId)
        operationStates[operationId] = .error(error)
        
        // Report to error manager
        ErrorManager.shared.handle(error, context: "Operation: \(operationId)")
    }
    
    func cancelOperation(_ operationId: String) {
        activeOperations.remove(operationId)
        operationStates.removeValue(forKey: operationId)
    }
    
    func getOperationState(_ operationId: String) -> LoadingState {
        return operationStates[operationId] ?? .idle
    }
    
    func isOperationLoading(_ operationId: String) -> Bool {
        return activeOperations.contains(operationId)
    }
    
    // MARK: - Convenience Methods
    func executeOperation<T>(
        _ operationId: String,
        message: String? = nil,
        operation: @escaping () async throws -> T
    ) async -> AsyncResult<T> {
        startOperation(operationId, message: message)
        
        do {
            let result = try await operation()
            completeOperation(operationId)
            return .success(result)
        } catch {
            let appError = convertToAppError(error)
            failOperation(operationId, error: appError)
            return .failure(appError)
        }
    }
    
    // MARK: - Private Methods
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
}

// MARK: - Loading View Modifier
struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)
            
            if isLoading {
                LoadingOverlayView(message: message)
            }
        }
    }
}

// MARK: - Loading Overlay View
struct LoadingOverlayView: View {
    let message: String?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                if let message = message {
                    Text(message)
                        .foregroundColor(.white)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - Retry Button View
struct RetryButtonView: View {
    let onRetry: () -> Void
    let isLoading: Bool
    
    var body: some View {
        Button(action: onRetry) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text(isLoading ? "Retrying..." : "Retry")
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .disabled(isLoading)
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(error.localizedDescription ?? "An unknown error occurred")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                if let onRetry = onRetry, error.isRetryable {
                    Button("Retry") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if let onDismiss = onDismiss {
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        systemImage: String = "tray",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
    }
}

// MARK: - View Extensions
extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
    
    func asyncContent<T>(
        result: AsyncResult<T>,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (T) -> some View
    ) -> some View {
        Group {
            switch result {
            case .loading:
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success(let value):
                content(value)
            case .failure(let error):
                ErrorStateView(
                    error: error,
                    onRetry: onRetry
                ) {
                    // Default dismiss action
                }
            }
        }
    }
}
