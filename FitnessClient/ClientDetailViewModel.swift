// ClientDetailViewModel.swift
import Foundation
import SwiftUI

@MainActor
class ClientDetailViewModel: ObservableObject {
    // Client whose details we are viewing
    @Published var client: UserResponse

    // Data fetched for this client
    @Published var trainingPlans: [TrainingPlan] = []
    @Published var isLoadingPlans = false
    @Published var errorMessage: String? = nil

    private let apiService: APIService
    private let authService: AuthService // Needed? Only if trainerID isn't reliably in APIService/client

    var trainerId: String? {
        // Get trainer ID reliably (e.g., from logged-in user)
        authService.loggedInUser?.id
    }

    init(client: UserResponse, apiService: APIService, authService: AuthService) {
        self.client = client
        self.apiService = apiService
        self.authService = authService
    }

    func fetchTrainingPlans() async {
        // Ensure we have the necessary IDs
        guard let currentTrainerId = trainerId else {
             errorMessage = "Could not identify the current trainer."
             print("ClientDetailVM: Trainer ID missing.")
             return
        }
        let clientId = client.id // Get client ID from the stored client object

        print("ClientDetailVM: Fetching training plans for client \(clientId) by trainer \(currentTrainerId)...")
        isLoadingPlans = true
        errorMessage = nil
        // Don't clear plans immediately? Or show empty state while loading?
        // trainingPlans = []

        // Construct the specific endpoint path
        let endpoint = "/trainer/clients/\(clientId)/plans"

        do {
            let fetchedPlans: [TrainingPlan] = try await apiService.GET(endpoint: endpoint)
            self.trainingPlans = fetchedPlans
            print("ClientDetailVM: Successfully fetched \(fetchedPlans.count) plans.")
            if fetchedPlans.isEmpty {
                 // self.errorMessage = "No training plans found for this client." // Optional message
            }
        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("ClientDetailVM: Error fetching plans (APINetworkError): \(error.localizedDescription)")
            self.trainingPlans = [] // Clear on error
        } catch {
            self.errorMessage = "An unexpected error occurred while fetching plans."
            print("ClientDetailVM: Unexpected error fetching plans: \(error.localizedDescription)")
            self.trainingPlans = [] // Clear on error
        }
        isLoadingPlans = false
    }
    
    // --- NEW: Delete Training Plan ---
    func deleteTrainingPlan(planId: String) async -> Bool { // Return Bool for success/failure
        guard let currentTrainerId = trainerId else {
            errorMessage = "Cannot verify trainer for delete operation."
            print("ClientDetailVM: Trainer ID missing for delete plan.")
            return false
        }
        // The backend endpoint includes clientId in the path for context and ownership check by trainer.
        // The trainer's own ID (from token) is used by the backend service for final authorization.
        print("ClientDetailVM: Attempting to delete plan \(planId) for client \(client.id) by trainer \(currentTrainerId)")

        // No specific isLoading for delete, can use general errorMessage for feedback
        // If you want per-item loading/disabled state, that's more complex UI.
        let previousErrorMessage = self.errorMessage // Store current error
        self.errorMessage = nil // Clear for this operation

        // Endpoint: /trainer/clients/{clientId}/plans/{planId}
        let endpoint = "/trainer/clients/\(client.id)/plans/\(planId)"

        do {
            // APIService.DELETE typically doesn't return a decodable body, just checks status
            try await apiService.DELETE(endpoint: endpoint)
            print("ClientDetailVM: Successfully deleted plan \(planId) from backend.")
            
            // Remove from local list optimistically
            self.trainingPlans.removeAll { $0.id == planId }
            
            // If the deleted plan was active, you might need logic to select a new active one,
            // or just let the list refresh.
            if trainingPlans.isEmpty {
                self.errorMessage = "No training plans assigned yet." // Update empty message
            }
            
            return true // Success
        } catch let error as APINetworkError {
            self.errorMessage = "Delete failed: \(error.localizedDescription)"
            print("ClientDetailVM: Error deleting plan (APINetworkError): \(error.localizedDescription)")
        } catch {
            self.errorMessage = "An unexpected error occurred while deleting the plan."
            print("ClientDetailVM: Unexpected error deleting plan: \(error.localizedDescription)")
        }
        
        // If error occurred, restore previous message if it wasn't related to this delete
        if self.errorMessage != nil && previousErrorMessage != nil && !previousErrorMessage!.contains("Delete failed") {
            // self.errorMessage = previousErrorMessage // Or just keep the delete error
        }
        return false // Failure
    }
}
