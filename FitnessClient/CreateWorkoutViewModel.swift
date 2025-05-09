// CreateWorkoutViewModel.swift
import Foundation
import SwiftUI

@MainActor
class CreateWorkoutViewModel: ObservableObject {
    // Form fields
    @Published var workoutName: String = ""
    @Published var dayOfWeek: Int? = nil // Optional day selection
    @Published var notes: String = ""
    @Published var sequence: Int = 0 // Or calculate next available based on existing workouts

    // State
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var didCreateSuccessfully = false

    // Dependencies
    let trainingPlan: TrainingPlan // Plan to add the workout to
    private let apiService: APIService
    private let currentWorkoutCount: Int // Pass current count to suggest next sequence

    // Options for Day Picker
    let daysOfWeek = ["Not Set", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    // Map display names to integer values (0 for "Not Set", 1 for Mon, etc.)
     var selectedDayDisplay: String {
         get { daysOfWeek[dayOfWeek ?? 0] }
         set { dayOfWeek = daysOfWeek.firstIndex(of: newValue) }
     }


    var canCreateWorkout: Bool {
        !workoutName.isEmpty && sequence >= 0 && !isLoading
    }

    init(trainingPlan: TrainingPlan, currentWorkoutCount: Int, apiService: APIService) {
        self.trainingPlan = trainingPlan
        self.apiService = apiService
        self.currentWorkoutCount = currentWorkoutCount
        self.sequence = currentWorkoutCount // Default sequence to next available slot
    }

    func createWorkout() async {
        guard canCreateWorkout else {
            if workoutName.isEmpty { errorMessage = "Workout name is required." }
            else if sequence < 0 { errorMessage = "Sequence must be zero or positive."}
            return
        }

        isLoading = true
        errorMessage = nil
        didCreateSuccessfully = false
        print("CreateWorkoutVM: Attempting to create workout '\(workoutName)' for plan \(trainingPlan.id)")

        let payload = CreateWorkoutPayload(
            name: workoutName,
            dayOfWeek: dayOfWeek == 0 ? nil : dayOfWeek, // Send nil if "Not Set" (index 0)
            notes: notes.isEmpty ? nil : notes,
            sequence: sequence
        )

        let endpoint = "/trainer/plans/\(trainingPlan.id)/workouts"

        do {
            let createdWorkout: Workout = try await apiService.POST(endpoint: endpoint, body: payload)
            print("CreateWorkoutVM: Successfully created workout ID: \(createdWorkout.id)")
            isLoading = false
            didCreateSuccessfully = true

        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("CreateWorkoutVM Error (APINetworkError): \(error.localizedDescription)")
            isLoading = false
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("CreateWorkoutVM Unexpected error: \(error.localizedDescription)")
            isLoading = false
        }
    }
}

// Defined CreateWorkoutPayload struct earlier or place it here/Models.swift
// struct CreateWorkoutPayload: Codable { ... }
