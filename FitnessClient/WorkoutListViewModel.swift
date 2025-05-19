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
    
    // --- Delete Workout ---
    func deleteWorkout(workoutId: String) async -> Bool {
        guard let currentTrainerId = authService.loggedInUser?.id else {
            errorMessage = "Authentication error."
            return false
        }
        // Ensure this trainer owns the plan this workout belongs to.
        // The workoutId itself is also checked for ownership by trainer in repo.
        if trainingPlan.trainerId != currentTrainerId {
            errorMessage = "Access Denied: You do not own the parent training plan."
            return false
        }

        print("WorkoutListVM: Deleting workout ID: \(workoutId) from plan \(trainingPlan.id)")
        isLoading = true // Can use general loading flag
        let previousErrorMessage = errorMessage
        errorMessage = nil

        // Endpoint: /trainer/plans/{planId}/workouts/{workoutId}
        let endpoint = "/trainer/plans/\(trainingPlan.id)/workouts/\(workoutId)"

        do {
            try await apiService.DELETE(endpoint: endpoint)
            print("WorkoutListVM: Successfully deleted workout \(workoutId)")
            
            self.workouts.removeAll { $0.id == workoutId } // Optimistic UI update
            if workouts.isEmpty {
                errorMessage = "This training plan doesn't have any workouts scheduled yet."
            }
            isLoading = false
            return true
        } catch let error as APINetworkError {
            self.errorMessage = "Delete failed: \(error.localizedDescription)"
            print("WorkoutListVM: Error deleting workout (APINetworkError): \(error.localizedDescription)")
        } catch {
            self.errorMessage = "An unexpected error occurred while deleting."
            print("WorkoutListVM: Unexpected error deleting workout: \(error.localizedDescription)")
        }
        if self.errorMessage != nil && previousErrorMessage != nil { /* ... restore previous error logic ... */ }
        isLoading = false
        return false
    }
}
