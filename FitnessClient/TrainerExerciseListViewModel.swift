// TrainerExerciseListViewModel.swift
import Foundation
import SwiftUI // For @MainActor

@MainActor // Ensures UI updates happen on the main thread
class TrainerExerciseListViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let apiService: APIService
    private let authService: AuthService // Needed to get current trainer's ID

    init(apiService: APIService, authService: AuthService) {
        self.apiService = apiService
        self.authService = authService
    }

    func fetchTrainerExercises() async {
        guard let trainer = authService.loggedInUser, trainer.role == "trainer" else {
            errorMessage = "User is not a trainer or not logged in."
            print("FetchExercises: Attempted by non-trainer or non-logged-in user.")
            return
        }
        
        // The endpoint might be just "/exercises" and your backend filters by trainer based on JWT,
        // OR it might be something like "/trainer/exercises" or "/exercises?trainerId={id}"
        // For this example, let's assume the backend filters by the authenticated trainer using just "/exercises"
        // If your Go API expects the trainerID in the path or query, adjust the endpoint.
        let endpoint = "/exercises" // Or "/trainer/\(trainer.id)/exercises" if needed
                                     // Or "/exercises?trainerId=\(trainer.id)"

        print("Fetching exercises for trainer: \(trainer.id) from endpoint: \(endpoint)")

        isLoading = true
        errorMessage = nil
        exercises = [] // Clear previous exercises

        do {
            // The APIService.GET method will automatically use the token from AuthService
            let fetchedExercises: [Exercise] = try await apiService.GET(endpoint: endpoint)
            self.exercises = fetchedExercises
            if fetchedExercises.isEmpty {
                print("No exercises found for this trainer.")
                // You could set a specific message for empty list if desired
                // self.errorMessage = "You haven't created any exercises yet."
            } else {
                print("Successfully fetched \(fetchedExercises.count) exercises.")
            }
        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("Error fetching trainer exercises (APINetworkError): \(error.localizedDescription)")
        } catch {
            self.errorMessage = "An unexpected error occurred while fetching exercises."
            print("Unexpected error fetching trainer exercises: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
