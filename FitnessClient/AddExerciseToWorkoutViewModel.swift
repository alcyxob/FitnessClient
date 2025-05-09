// AddExerciseToWorkoutViewModel.swift
import Foundation
import SwiftUI

@MainActor
class AddExerciseToWorkoutViewModel: ObservableObject {
    // Form Fields
    @Published var selectedExerciseId: String? = nil
    @Published var sets: String = "" // Use String for TextField, convert to Int? later
    @Published var reps: String = ""
    @Published var rest: String = ""
    @Published var tempo: String = ""
    @Published var weight: String = ""
    @Published var duration: String = ""
    @Published var sequence: Int = 0
    @Published var trainerNotes: String = ""

    // Data Sources
    @Published var availableExercises: [Exercise] = [] // Trainer's exercise library
    @Published var isLoadingExercises = false

    // State
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var didAssignSuccessfully = false

    // Dependencies
    let workout: Workout // Workout to add the exercise to
    private let apiService: APIService
    private let currentAssignmentCount: Int

    var canAssign: Bool {
        selectedExerciseId != nil && !isLoading
    }

    init(workout: Workout, currentAssignmentCount: Int, apiService: APIService) {
        self.workout = workout
        self.apiService = apiService
        self.currentAssignmentCount = currentAssignmentCount
        self.sequence = currentAssignmentCount // Default sequence
    }

    func loadTrainerExercises() async {
            guard availableExercises.isEmpty && !isLoadingExercises else {
                print("AddExToWorkoutVM: Exercises already loaded or fetch already in progress.")
                return
            }
            
            print("AddExToWorkoutVM: Attempting to load trainer's available exercises...")
            // Set initial state for loading
            self.isLoadingExercises = true
            self.errorMessage = nil // Clear previous exercise loading errors
            
            var fetchedItemsLocal: [Exercise] = [] // Use a local variable
            var errorOccurred: Error? = nil

            do {
                let endpoint = "/exercises"
                print("AddExToWorkoutVM: Calling API: GET \(endpoint)")
                fetchedItemsLocal = try await apiService.GET(endpoint: endpoint) // Assign to local var
                
                print("AddExToWorkoutVM: Loaded \(fetchedItemsLocal.count) exercises from API.")
                if !fetchedItemsLocal.isEmpty {
                    print("AddExToWorkoutVM: First exercise from API: \(fetchedItemsLocal[0].name)")
                }
            } catch let apiErr as APINetworkError {
                errorOccurred = apiErr
                print("AddExToWorkoutVM: Error loading exercises (APINetworkError): \(apiErr.localizedDescription)")
            } catch let generalErr {
                errorOccurred = generalErr
                print("AddExToWorkoutVM: Unexpected error loading exercises: \(generalErr.localizedDescription)")
            }
            
            // --- CRITICAL: Update all relevant @Published properties together AFTER await ---
            // This block will run on the MainActor
            self.availableExercises = fetchedItemsLocal // Assign fetched items (or empty if error)
            
            if let errorOccurred = errorOccurred {
                self.errorMessage = "Could not load your exercises: \(errorOccurred.localizedDescription)"
                // Ensure availableExercises is empty if there was an error during fetch
                self.availableExercises = []
            } else {
                self.errorMessage = nil // Clear error if successful
            }
            
            self.isLoadingExercises = false // Set loading to false *after* data is potentially set

            print("AddExToWorkoutVM: loadTrainerExercises finished. isLoadingExercises: \(self.isLoadingExercises), Exercises count: \(self.availableExercises.count), Error: \(self.errorMessage ?? "None")")
        }

    func assignExerciseToWorkout() async {
        guard let exerciseId = selectedExerciseId else {
            errorMessage = "Please select an exercise."
            return
        }
        // Basic validation for sequence
        guard sequence >= 0 else {
            errorMessage = "Sequence must be a positive number."
            return
        }

        isLoading = true
        errorMessage = nil
        didAssignSuccessfully = false
        print("AddExToWorkoutVM: Assigning exercise \(exerciseId) to workout \(workout.id)")

        // Convert String sets to Int?
        let setsInt: Int? = Int(sets) // Returns nil if conversion fails
        
        let payload = AssignExerciseToWorkoutPayload(
            exerciseId: exerciseId,
            sets: setsInt,
            reps: reps.isEmpty ? nil : reps,
            rest: rest.isEmpty ? nil : rest,
            tempo: tempo.isEmpty ? nil : tempo,
            weight: weight.isEmpty ? nil : weight,
            duration: duration.isEmpty ? nil : duration,
            sequence: sequence,
            trainerNotes: trainerNotes.isEmpty ? nil : trainerNotes
        )

        let endpoint = "/trainer/workouts/\(workout.id)/exercises"

        do {
            let createdAssignment: Assignment = try await apiService.POST(endpoint: endpoint, body: payload)
            print("AddExToWorkoutVM: Successfully assigned exercise, new assignment ID: \(createdAssignment.id)")
            isLoading = false
            didAssignSuccessfully = true

        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("AddExToWorkoutVM Error (APINetworkError): \(error.localizedDescription)")
            isLoading = false
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("AddExToWorkoutVM Unexpected error: \(error.localizedDescription)")
            isLoading = false
        }
    }
}

// --- DTO for Assign Exercise to Workout Request Body ---
// Matches Go's AssignExerciseToWorkoutRequest
struct AssignExerciseToWorkoutPayload: Codable {
    let exerciseId: String // Note: Backend uses exerciseId, not exerciseID from domain here
    var sets: Int?
    var reps: String?
    var rest: String?
    var tempo: String?
    var weight: String?
    var duration: String?
    let sequence: Int
    var trainerNotes: String?
}
