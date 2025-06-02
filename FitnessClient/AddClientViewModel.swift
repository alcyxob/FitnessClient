// AddClientViewModel.swift
import Foundation
import SwiftUI

@MainActor
class AddClientViewModel: ObservableObject {
    @Published var clientEmail: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var didAddClientSuccessfully = false // To signal success

    private let apiService: APIService
    private let toastManager: ToastManager

    init(apiService: APIService, toastManager: ToastManager) {
        self.apiService = apiService;
        self.toastManager = toastManager
    }

    func addClient() async {
        guard !clientEmail.isEmpty, isValidEmail(clientEmail) else {
            errorMessage = "Please enter a valid client email address."
            return
        }

        isLoading = true
        errorMessage = nil
        didAddClientSuccessfully = false
        print("ViewModel: Attempting to add client: \(clientEmail)")

        let payload = AddClientPayload(clientEmail: clientEmail)

        do {
            // The response type is UserResponse (the added client details)
            let addedClient: UserResponse = try await apiService.POST(endpoint: "/trainer/clients", body: payload)
            print("ViewModel: Successfully added client: \(addedClient.email)")
            isLoading = false
            didAddClientSuccessfully = true // Signal success
            toastManager.showToast(style: .success, message: "Client '\(addedClient.name)' added!")

        } catch let error as APINetworkError {
            // More specific error handling based on status code if needed
            if case .serverError(let statusCode, let message) = error {
                 if statusCode == 404 {
                    self.errorMessage = "Client with this email not found."
                 } else if statusCode == 403 {
                     self.errorMessage = message ?? "Client cannot be added (already assigned or not a client role)."
                 } else {
                     self.errorMessage = message ?? error.localizedDescription
                 }
            } else {
                 self.errorMessage = error.localizedDescription
            }
            print("ViewModel Error adding client (APINetworkError): \(self.errorMessage ?? "Unknown API error")")
            isLoading = false
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("ViewModel Unexpected error adding client: \(error.localizedDescription)")
            isLoading = false
        }
    }

    // Basic email validation helper
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
