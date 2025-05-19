// ClientPlansViewModel.swift
import Foundation
import SwiftUI

@MainActor
class ClientPlansViewModel: ObservableObject {
    @Published var trainingPlans: [TrainingPlan] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // No need for authService here if APIService handles token transparently
    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
        print("ClientPlansViewModel: Initialized.")
    }

    func fetchMyTrainingPlans() async {
        // Client ID is derived from the token by the APIService/backend
        print("ClientPlansVM: Fetching my training plans...")
        isLoading = true
        errorMessage = nil
        // trainingPlans = [] // Optional: clear or show stale

        let endpoint = "/client/plans" // Client-specific endpoint

        do {
            let fetchedPlans: [TrainingPlan] = try await apiService.GET(endpoint: endpoint)
            self.trainingPlans = fetchedPlans
            print("ClientPlansVM: Successfully fetched \(fetchedPlans.count) plans.")
            if fetchedPlans.isEmpty {
                self.errorMessage = "You don't have any training plans assigned yet."
            }
        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("ClientPlansVM: Error fetching plans (APINetworkError): \(error.localizedDescription)")
            self.trainingPlans = []
        } catch {
            self.errorMessage = "An unexpected error occurred while fetching your plans."
            print("ClientPlansVM: Unexpected error fetching plans: \(error.localizedDescription)")
            self.trainingPlans = []
        }
        isLoading = false
        print("ClientPlansVM: fetchMyTrainingPlans finished. isLoading: \(isLoading), Count: \(trainingPlans.count), Error: \(errorMessage ?? "None")")
    }
}
