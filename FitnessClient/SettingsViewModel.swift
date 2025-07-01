// SettingsViewModel.swift
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let apiService: APIService
    private let authService: AuthService // To update the global user object
    private let appModeManager: AppModeManager

    init(apiService: APIService, authService: AuthService, appModeManager: AppModeManager) {
        self.apiService = apiService
        self.authService = authService
        self.appModeManager = appModeManager
    }

    func activateTrainerRole() async {
        print("SettingsVM: Activating trainer role...")
        isLoading = true
        errorMessage = nil

        // DTO for the request (can be empty if no body needed)
        struct EmptyPayload: Encodable {}

        let endpoint = "/users/me/activate-trainer-role" // Example endpoint

        do {
            // The API call should return the FULL, updated UserResponse object
            let updatedUser: UserResponse = try await apiService.POST(endpoint: endpoint, body: EmptyPayload())
            
            print("SettingsVM: Successfully activated trainer role. Updating global user state.")
            // --- CRITICAL STEP ---
            // Update the central AuthService with the new user details
            authService.updateLoggedInUser(with: updatedUser)

        } catch let error as APINetworkError {
            self.errorMessage = "Failed to activate trainer role: \(error.localizedDescription)"
            print("SettingsVM: Error activating trainer role (APINetworkError): \(error.localizedDescription)")
        } catch {
            self.errorMessage = "An unexpected error occurred."
            print("SettingsVM: Unexpected error activating trainer role: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
