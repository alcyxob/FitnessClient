// EditWorkoutViewModel.swift
import Foundation
import SwiftUI

@MainActor
class EditWorkoutViewModel: ObservableObject {
    // Workout being edited - its properties will be bound to form fields
    @Published var workout: Workout // Start with a copy of the workout to edit

    // Original IDs (don't change)
    private let originalWorkoutId: String
    private let originalPlanId: String // Needed for the API endpoint

    // State Management
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var didUpdateSuccessfully = false

    private let apiService: APIService

    // Options for Day Picker (same as CreateWorkoutViewModel)
    let daysOfWeek = ["Not Set", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    // Binding helper for Picker using display names
    var selectedDayDisplay: String {
        get { daysOfWeek[workout.dayOfWeek ?? 0] } // Use workout.dayOfWeek
        set { workout.dayOfWeek = daysOfWeek.firstIndex(of: newValue) } // Update workout.dayOfWeek
    }
    
    // Computed property for validation
    var canSaveChanges: Bool {
        !workout.name.isEmpty && workout.sequence >= 0 && !isLoading
    }

    init(workoutToEdit: Workout, apiService: APIService) {
        // Initialize with the workout to edit.
        // Since Workout is a struct, this 'workoutToEdit' is a copy.
        // Changes to self.workout will not affect the original list until saved.
        self.workout = workoutToEdit
        self.originalWorkoutId = workoutToEdit.id
        self.originalPlanId = workoutToEdit.trainingPlanId
        self.apiService = apiService
        print("EditWorkoutVM: Initialized for workout ID: \(workoutToEdit.id), Name: \(workoutToEdit.name)")
    }

    func saveChanges() async {
        guard canSaveChanges else {
            if workout.name.isEmpty { errorMessage = "Workout name cannot be empty." }
            else if workout.sequence < 0 { errorMessage = "Sequence must be zero or positive."}
            return
        }

        isLoading = true
        errorMessage = nil
        didUpdateSuccessfully = false
        print("EditWorkoutVM: Attempting to update workout ID: \(originalWorkoutId)")

        // Use CreateWorkoutPayload DTO for the update body,
        // assuming your backend PUT /trainer/plans/{planId}/workouts/{workoutId}
        // expects a similar structure for updatable fields.
        let payload = CreateWorkoutPayload(
            name: workout.name,
            dayOfWeek: workout.dayOfWeek == 0 ? nil : workout.dayOfWeek, // Send nil if "Not Set"
            notes: workout.notes?.isEmpty == true ? nil : workout.notes,
            sequence: workout.sequence
        )

        let endpoint = "/trainer/plans/\(originalPlanId)/workouts/\(originalWorkoutId)"

        do {
            // APIService.PUT should take the endpoint and body
            let updatedWorkoutFromServer: Workout = try await apiService.PUT(endpoint: endpoint, body: payload)
            
            print("EditWorkoutVM: Successfully updated workout: \(updatedWorkoutFromServer.name)")
            // Update self.workout with the response from server for full consistency
            // (e.g., if backend modified 'updatedAt' or other fields)
            self.workout = updatedWorkoutFromServer // Reflects server state
            isLoading = false
            didUpdateSuccessfully = true

        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("EditWorkoutVM: Error updating workout (APINetworkError): \(error.localizedDescription)")
            isLoading = false
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("EditWorkoutVM: Unexpected error updating workout: \(error.localizedDescription)")
            isLoading = false
        }
    }
}
