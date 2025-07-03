// BaseViewModel.swift
import Foundation
import SwiftUI

// MARK: - Base ViewModel Protocol
protocol BaseViewModelProtocol: ObservableObject {
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var loadingStateManager: LoadingStateManager { get }
    
    func handleError(_ error: Error, context: String?)
    func clearError()
    func retry()
}

// MARK: - Base ViewModel Implementation
@MainActor
class BaseViewModel: ObservableObject, BaseViewModelProtocol {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loadingStateManager = LoadingStateManager()
    
    private var retryAction: (() async throws -> Void)?
    
    // MARK: - Error Handling
    func handleError(_ error: Error, context: String? = nil) {
        let appError = convertToAppError(error)
        errorMessage = appError.localizedDescription
        isLoading = false
        
        // Report to global error manager
        ErrorManager.shared.handle(appError, context: context)
        
        // Log error locally
        logError(appError, context: context)
    }
    
    func clearError() {
        errorMessage = nil
        ErrorManager.shared.clearError()
    }
    
    func retry() {
        guard let retryAction = retryAction else { return }
        
        clearError()
        Task {
            do {
                try await retryAction()
            } catch {
                handleError(error, context: "Retry operation")
            }
        }
    }
    
    // MARK: - Safe Async Execution
    func safeExecute(
        operationId: String = UUID().uuidString,
        loadingMessage: String? = nil,
        context: String? = nil,
        retryable: Bool = true,
        operation: @escaping () async throws -> Void
    ) async {
        // Store retry action if retryable
        if retryable {
            retryAction = operation
        }
        
        isLoading = true
        clearError()
        
        let result = await loadingStateManager.executeOperation(
            operationId,
            message: loadingMessage
        ) {
            try await operation()
        }
        
        switch result {
        case .loading:
            break // Already handled by loading state manager
        case .success:
            isLoading = false
        case .failure(let error):
            handleError(error, context: context)
        }
    }
    
    func safeExecute<T>(
        operationId: String = UUID().uuidString,
        loadingMessage: String? = nil,
        context: String? = nil,
        operation: @escaping () async throws -> T
    ) async -> T? {
        isLoading = true
        clearError()
        
        let result = await loadingStateManager.executeOperation(
            operationId,
            message: loadingMessage
        ) {
            try await operation()
        }
        
        switch result {
        case .loading:
            return nil
        case .success(let value):
            isLoading = false
            return value
        case .failure(let error):
            handleError(error, context: context)
            return nil
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
    
    private func logError(_ error: AppError, context: String?) {
        print("🚨 ViewModel Error: \(error.localizedDescription ?? "Unknown error")")
        if let context = context {
            print("📍 Context: \(context)")
        }
    }
}

// MARK: - Specialized ViewModels
@MainActor
class ListViewModel<T>: BaseViewModel {
    @Published var items: [T] = []
    @Published var isEmpty = false
    
    func updateItems(_ newItems: [T]) {
        items = newItems
        isEmpty = newItems.isEmpty
    }
    
    func clearItems() {
        items = []
        isEmpty = true
    }
    
    func addItem(_ item: T) {
        items.append(item)
        isEmpty = false
    }
    
    func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        isEmpty = items.isEmpty
    }
}

@MainActor
class DetailViewModel<T>: BaseViewModel {
    @Published var item: T?
    @Published var isItemLoaded = false
    
    func updateItem(_ newItem: T?) {
        item = newItem
        isItemLoaded = newItem != nil
    }
    
    func clearItem() {
        item = nil
        isItemLoaded = false
    }
}

// MARK: - Form ViewModel
@MainActor
class FormViewModel: BaseViewModel {
    @Published var isSubmitting = false
    @Published var validationErrors: [String: String] = [:]
    @Published var isFormValid = false
    
    func addValidationError(for field: String, message: String) {
        validationErrors[field] = message
        updateFormValidation()
    }
    
    func clearValidationError(for field: String) {
        validationErrors.removeValue(forKey: field)
        updateFormValidation()
    }
    
    func clearAllValidationErrors() {
        validationErrors.removeAll()
        updateFormValidation()
    }
    
    private func updateFormValidation() {
        isFormValid = validationErrors.isEmpty
    }
    
    func submitForm(
        operationId: String = "form_submit",
        operation: @escaping () async throws -> Void
    ) async {
        guard isFormValid else {
            handleError(AppError.invalidInput(field: "form"), context: "Form validation failed")
            return
        }
        
        isSubmitting = true
        
        await safeExecute(
            operationId: operationId,
            loadingMessage: "Submitting...",
            context: "Form submission"
        ) { [weak self] in
            try await operation()
            await MainActor.run {
                self?.isSubmitting = false
            }
        }
    }
}

// MARK: - View Model Factory
@MainActor
class ViewModelFactory {
    static func createListViewModel<T>() -> ListViewModel<T> {
        return ListViewModel<T>()
    }
    
    static func createDetailViewModel<T>() -> DetailViewModel<T> {
        return DetailViewModel<T>()
    }
    
    static func createFormViewModel() -> FormViewModel {
        return FormViewModel()
    }
}
