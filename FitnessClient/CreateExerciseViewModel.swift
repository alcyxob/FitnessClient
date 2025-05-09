// CreateExerciseViewModel.swift
import Foundation
import SwiftUI

@MainActor
class CreateExerciseViewModel: ObservableObject {
    // Properties to bind to the form fields
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var muscleGroup: String = ""
    @Published var executionTechnic: String = ""
    @Published var applicability: String = "" // e.g., Home, Gym
    @Published var difficulty: String = ""    // e.g., Novice, Medium, Advanced
    @Published var videoUrl: String = ""      // Optional

    // For picker options
    let applicabilityOptions = ["Any", "Home", "Gym"]
    let difficultyOptions = ["Novice", "Medium", "Advanced"]


    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var didCreateExercise = false // To signal successful creation

    private let apiService: APIService
    // No need for authService directly if APIService handles token

    init(apiService: APIService) {
        self.apiService = apiService
        // Set default picker values if desired
        self.applicability = applicabilityOptions.first ?? "Any"
        self.difficulty = difficultyOptions.first ?? "Novice"
    }

    func createExercise() async {
        guard !name.isEmpty else {
            errorMessage = "Exercise name cannot be empty."
            return
        }
        // Add more client-side validation if needed

        isLoading = true
        errorMessage = nil
        didCreateExercise = false

        let payload = CreateExercisePayload(
            name: name,
            description: description.isEmpty ? nil : description, // Send nil if empty for optional fields
            muscleGroup: muscleGroup.isEmpty ? nil : muscleGroup,
            executionTechnic: executionTechnic.isEmpty ? nil : executionTechnic,
            applicability: applicability.isEmpty ? nil : applicability,
            difficulty: difficulty.isEmpty ? nil : difficulty,
            videoUrl: videoUrl.isEmpty ? nil : videoUrl
        )

        do {
            // APIService.POST should handle token, content-type etc.
            // The response type here is Exercise (matching Go's ExerciseResponse mapped to Swift Exercise)
            let createdExercise: Exercise = try await apiService.POST(endpoint: "/exercises", body: payload)
            
            print("Successfully created exercise: \(createdExercise.name)")
            isLoading = false
            didCreateExercise = true // Signal success to the view
        } catch let error as APINetworkError {
            errorMessage = error.localizedDescription
            print("Error creating exercise (APINetworkError): \(error.localizedDescription)")
            isLoading = false
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("Unexpected error creating exercise: \(error.localizedDescription)")
            isLoading = false
        }
    }
}
