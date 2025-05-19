// ClientWorkoutsViewModel.swift
import Foundation
import SwiftUI

@MainActor
class ClientWorkoutsViewModel: ObservableObject {
    @Published var workouts: [Workout] = [] // From Models.swift
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    let trainingPlan: TrainingPlan // The plan these workouts belong to
    private let apiService: APIService
    // We don't necessarily need AuthService here if clientID is not explicitly passed to endpoint
    // as APIService should use the client's token.

    // To display day names like in trainer's WorkoutListViewModel
    let daysOfWeek = ["Not Set", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


    init(trainingPlan: TrainingPlan, apiService: APIService) {
        self.trainingPlan = trainingPlan
        self.apiService = apiService
        print("ClientWorkoutsVM: Initialized for plan: \(trainingPlan.name) (\(trainingPlan.id))")
    }

    func fetchMyWorkoutsForPlan() async {
        print("ClientWorkoutsVM: Fetching workouts for my plan ID: \(trainingPlan.id)")
        isLoading = true
        errorMessage = nil
        // workouts = [] // Optional: clear or show stale

        // Client ID is implicit in the token used by APIService
        let endpoint = "/client/plans/\(trainingPlan.id)/workouts"

        do {
            let fetchedWorkouts: [Workout] = try await apiService.GET(endpoint: endpoint)
            // Sort by sequence locally if backend doesn't guarantee it
            self.workouts = fetchedWorkouts.sorted { $0.sequence < $1.sequence }
            print("ClientWorkoutsVM: Successfully fetched \(fetchedWorkouts.count) workouts for plan.")
            if fetchedWorkouts.isEmpty {
                self.errorMessage = "This training plan doesn't have any workouts scheduled yet."
            }
        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("ClientWorkoutsVM: Error fetching workouts (APINetworkError): \(error.localizedDescription)")
            self.workouts = []
        } catch {
            self.errorMessage = "An unexpected error occurred while fetching workouts for your plan."
            print("ClientWorkoutsVM: Unexpected error fetching workouts: \(error.localizedDescription)")
            self.workouts = []
        }
        isLoading = false
        print("ClientWorkoutsVM: fetchMyWorkoutsForPlan finished. isLoading: \(isLoading), Count: \(workouts.count), Error: \(errorMessage ?? "None")")
    }
}
