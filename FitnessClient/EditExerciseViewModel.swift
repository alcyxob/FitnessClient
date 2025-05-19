// EditExerciseViewModel.swift
import Foundation
import SwiftUI

@MainActor
class EditExerciseViewModel: ObservableObject {
    // Exercise being edited
    @Published var exercise: Exercise // Holds the state of the form fields

    // Original exercise ID (doesn't change)
    private let originalExerciseId: String

    // State Management
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var didUpdateSuccessfully = false

    private let apiService: APIService
    // No need for authService directly if APIService handles token

    var canSaveChanges: Bool {
        !exercise.name.isEmpty && !isLoading
    }

    // Options for pickers (same as CreateExerciseViewModel)
    let applicabilityOptions = ["Any", "Home", "Gym"] // Consider making these global constants or part of Exercise model
    let difficultyOptions = ["Novice", "Medium", "Advanced"]

    init(exerciseToEdit: Exercise, apiService: APIService) {
        // Initialize with a copy so changes don't reflect immediately in list
        // If Exercise is a struct (value type), direct assignment IS a copy.
        self.exercise = exerciseToEdit
        self.originalExerciseId = exerciseToEdit.id // Store the original ID
        self.apiService = apiService
        print("EditExerciseVM: Initialized for exercise ID: \(exerciseToEdit.id), Name: \(exerciseToEdit.name)")
    }

    func saveChanges() async {
        guard canSaveChanges else {
            if exercise.name.isEmpty { errorMessage = "Exercise name cannot be empty." }
            return
        }

        isLoading = true
        errorMessage = nil
        didUpdateSuccessfully = false
        print("EditExerciseVM: Attempting to update exercise ID: \(originalExerciseId)")

        // Use CreateExercisePayload for the update body, as it matches the fields
        // Ensure your Go backend's PUT /exercises/{id} expects this structure.
        let payload = CreateExercisePayload( // Reusing DTO from Create
            name: exercise.name,
            description: exercise.description, // Pass current values from @Published exercise
            muscleGroup: exercise.muscleGroup,
            executionTechnic: exercise.executionTechnic,
            applicability: exercise.applicability,
            difficulty: exercise.difficulty,
            videoUrl: exercise.videoUrl
        )

        let endpoint = "/exercises/\(originalExerciseId)" // Use original ID for endpoint

        do {
            // APIService.PUT should take the endpoint and body
            let updatedExerciseFromServer: Exercise = try await apiService.PUT(endpoint: endpoint, body: payload)
            
            print("EditExerciseVM: Successfully updated exercise: \(updatedExerciseFromServer.name)")
            // Optionally update self.exercise with the response from server for consistency
            self.exercise = updatedExerciseFromServer
            isLoading = false
            didUpdateSuccessfully = true

        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("EditExerciseVM: Error updating exercise (APINetworkError): \(error.localizedDescription)")
            isLoading = false
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("EditExerciseVM: Unexpected error updating exercise: \(error.localizedDescription)")
            isLoading = false
        }
    }
}
