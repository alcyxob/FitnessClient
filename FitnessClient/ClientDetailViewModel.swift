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
}
