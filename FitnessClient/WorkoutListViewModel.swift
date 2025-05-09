// WorkoutListViewModel.swift
import Foundation
import SwiftUI

@MainActor
class WorkoutListViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    let trainingPlan: TrainingPlan // The plan these workouts belong to
    private let apiService: APIService
    private let authService: AuthService // May need for trainerID validation if apiService doesn't implicitly handle
    
    let daysOfWeek = ["Not Set", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var trainerId: String? { authService.loggedInUser?.id }

    init(trainingPlan: TrainingPlan, apiService: APIService, authService: AuthService) {
        self.trainingPlan = trainingPlan
        self.apiService = apiService
        self.authService = authService
    }

    func fetchWorkoutsForPlan() async {
        // Avoid unnecessary fetches if data exists? Optional.
        // guard workouts.isEmpty else { return }

        guard let currentTrainerId = trainerId else {
            errorMessage = "Cannot verify trainer."
            print("WorkoutListVM: Trainer ID missing.")
            return
        }
        // Basic check: Does this trainer even own the plan we're fetching for?
        // Although the API endpoint itself should be protected.
        guard trainingPlan.trainerId == currentTrainerId else {
            errorMessage = "Access Denied: You do not own this training plan."
            print("WorkoutListVM: Access denied. Trainer \(currentTrainerId) does not own plan \(trainingPlan.id).")
            return
        }


        print("WorkoutListVM: Fetching workouts for plan ID: \(trainingPlan.id)")
        isLoading = true
        errorMessage = nil
        // workouts = [] // Clear or show stale?

        let endpoint = "/trainer/plans/\(trainingPlan.id)/workouts"

        do {
            let fetchedWorkouts: [Workout] = try await apiService.GET(endpoint: endpoint)
            // Sort by sequence locally if backend doesn't guarantee it
            self.workouts = fetchedWorkouts.sorted { $0.sequence < $1.sequence }
            print("WorkoutListVM: Successfully fetched \(fetchedWorkouts.count) workouts.")
        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("WorkoutListVM: Error fetching workouts (APINetworkError): \(error.localizedDescription)")
            self.workouts = []
        } catch {
            self.errorMessage = "An unexpected error occurred fetching workouts."
            print("WorkoutListVM: Unexpected error fetching workouts: \(error.localizedDescription)")
            self.workouts = []
        }
        isLoading = false
    }
}
