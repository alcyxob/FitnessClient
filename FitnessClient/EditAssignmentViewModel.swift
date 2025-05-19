// EditAssignmentViewModel.swift
import Foundation
import SwiftUI

@MainActor
class EditAssignmentViewModel: ObservableObject {
    // The assignment being edited. Its properties will be bound to form fields.
    @Published var assignment: Assignment // This will be a copy of the original

    // Original IDs (don't change)
    private let originalAssignmentId: String
    private let originalWorkoutId: String // Needed for the API endpoint

    // Data Sources for changing the exercise (optional feature)
    @Published var availableExercises: [Exercise] = []
    @Published var isLoadingExercises = false
    @Published var selectedExerciseId: String // Initialize with current exerciseId

    // State Management
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var didUpdateSuccessfully = false

    private let apiService: APIService
    // authService might be needed if fetching exercises requires strict trainer ownership check beyond token

    var canSaveChanges: Bool {
        // Add more validation if needed (e.g., sequence >= 0)
        !isLoading && !selectedExerciseId.isEmpty // Must have an exercise selected
    }

    init(assignmentToEdit: Assignment, apiService: APIService) {
        self.assignment = assignmentToEdit // Assignment is a struct, so this is a copy
        self.originalAssignmentId = assignmentToEdit.id
        self.originalWorkoutId = assignmentToEdit.workoutId
        self.selectedExerciseId = assignmentToEdit.exerciseId // Initialize picker with current exercise
        self.apiService = apiService
        print("EditAssignmentVM: Initialized for assignment ID: \(assignmentToEdit.id), Exercise: \(assignmentToEdit.exercise?.name ?? assignmentToEdit.exerciseId)")
    }

    // Call this if you allow changing the exercise within the edit form
    func loadTrainerExercises() async {
        guard availableExercises.isEmpty && !isLoadingExercises else { return }
        print("EditAssignmentVM: Loading trainer's available exercises for picker...")
        isLoadingExercises = true
        // No specific error message for this load, general errorMessage can be used if needed
        
        do {
            let fetchedExercises: [Exercise] = try await apiService.GET(endpoint: "/exercises")
            self.availableExercises = fetchedExercises
            print("EditAssignmentVM: Loaded \(fetchedExercises.count) exercises.")
        } catch {
            print("EditAssignmentVM: Error loading exercises: \(error.localizedDescription)")
            // self.errorMessage = "Could not load exercise library."
        }
        isLoadingExercises = false
    }

    func saveChanges() async {
        guard canSaveChanges else {
            if selectedExerciseId.isEmpty { errorMessage = "An exercise must be selected."}
            return
        }

        isLoading = true
        errorMessage = nil
        didUpdateSuccessfully = false
        print("EditAssignmentVM: Attempting to update assignment ID: \(originalAssignmentId) in workout \(originalWorkoutId)")

        // Construct the payload. Use AssignExerciseToWorkoutPayload as it matches backend DTO for PUT.
        let payload = AssignExerciseToWorkoutPayload( // From Models.swift or AddExerciseToWorkoutViewModel
            exerciseId: selectedExerciseId, // Use the potentially changed exercise ID
            sets: assignment.sets,
            reps: assignment.reps,
            rest: assignment.rest,
            tempo: assignment.tempo,
            weight: assignment.weight,
            duration: assignment.duration,
            sequence: assignment.sequence,
            trainerNotes: assignment.trainerNotes
        )

        let endpoint = "/trainer/workouts/\(originalWorkoutId)/assignments/\(originalAssignmentId)"

        do {
            let updatedAssignmentFromServer: Assignment = try await apiService.PUT(endpoint: endpoint, body: payload)
            
            print("EditAssignmentVM: Successfully updated assignment: \(updatedAssignmentFromServer.id)")
            // Update self.assignment with the response from server for full consistency
            // This is important if the server modifies/validates any data (e.g., updatedAt)
            self.assignment = updatedAssignmentFromServer
            isLoading = false
            didUpdateSuccessfully = true

        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("EditAssignmentVM: Error updating assignment (APINetworkError): \(error.localizedDescription)")
            isLoading = false
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("EditAssignmentVM: Unexpected error updating assignment: \(error.localizedDescription)")
            isLoading = false
        }
    }
}
