// CreateTrainingPlanViewModel.swift
import Foundation
import SwiftUI

@MainActor
class CreateTrainingPlanViewModel: ObservableObject {
    // Properties bound to the Form fields
    @Published var planName: String = ""
    @Published var description: String = ""
    @Published var startDate: Date? = nil
    @Published var endDate: Date? = nil
    @Published var isActive: Bool = false // Default to not active?

    // Toggles for optional dates
    @Published var includeStartDate = false
    @Published var includeEndDate = false

    // State Management
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var didCreateSuccessfully = false // Signal success

    // Dependencies
    let client: UserResponse // The client this plan is for
    private let apiService: APIService

    // Computed property for validation
    var canCreatePlan: Bool {
        !planName.isEmpty && !isLoading
    }

    init(client: UserResponse, apiService: APIService) {
        self.client = client
        self.apiService = apiService
    }

    func createTrainingPlan() async {
        guard canCreatePlan else {
            // This shouldn't happen if button is disabled, but good practice
            if planName.isEmpty {
                errorMessage = "Plan name cannot be empty."
            }
            return
        }

        isLoading = true
        errorMessage = nil
        didCreateSuccessfully = false
        print("CreatePlanVM: Attempting to create plan '\(planName)' for client \(client.id)")

        // Construct the payload DTO
        let payload = CreateTrainingPlanPayload(
            name: planName,
            description: description.isEmpty ? nil : description,
            startDate: includeStartDate ? startDate : nil, // Use nil if toggle is off
            endDate: includeEndDate ? endDate : nil,       // Use nil if toggle is off
            isActive: isActive
        )

        let endpoint = "/trainer/clients/\(client.id)/plans"

        do {
            // Make the API Call (expecting TrainingPlan response)
            let createdPlan: TrainingPlan = try await apiService.POST(endpoint: endpoint, body: payload)

            print("CreatePlanVM: Successfully created plan ID: \(createdPlan.id)")
            isLoading = false
            didCreateSuccessfully = true // Signal success to the view

        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("CreatePlanVM: Error creating plan (APINetworkError): \(error.localizedDescription)")
            isLoading = false
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("CreatePlanVM: Unexpected error creating plan: \(error.localizedDescription)")
            isLoading = false
        }
    }
}

// --- DTO for Create Training Plan Request Body ---
// Define this here or in Models.swift if preferred
struct CreateTrainingPlanPayload: Codable {
    let name: String
    var description: String? // Use optional if Go expects null for empty
    var startDate: Date?
    var endDate: Date?
    let isActive: Bool
}
