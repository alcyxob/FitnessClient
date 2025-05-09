// AssignmentListViewModel.swift
import Foundation
import SwiftUI

@MainActor
class AssignmentListViewModel: ObservableObject {
    @Published var assignmentsWithExercises: [Assignment] = [] // Store assignments with populated exercise details
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    let workout: Workout // The workout these assignments belong to
    private let apiService: APIService
    // No direct need for authService if apiService handles token and trainerID is on workout for context

    init(workout: Workout, apiService: APIService) {
        self.workout = workout
        self.apiService = apiService
    }

    func fetchAssignmentsForWorkout() async {
        print("AssignListVM: Fetching assignments for workout ID: \(workout.id)")
        isLoading = true
        errorMessage = nil
        // assignmentsWithExercises = [] // Clear or show stale?

        let endpoint = "/trainer/workouts/\(workout.id)/assignments"

        do {
            // 1. Fetch the raw assignments
            let rawAssignments: [Assignment] = try await apiService.GET(endpoint: endpoint)
            print("AssignListVM: Fetched \(rawAssignments.count) raw assignments.")

            // 2. Fetch exercise details for each assignment
            // This can be slow if many assignments. Consider batch fetching if API supports it.
            var populatedAssignments: [Assignment] = []
            for var assignment in rawAssignments { // Make 'assignment' mutable to set .exercise
                do {
                    // Assuming /exercises/{id} endpoint exists to get single exercise detail
                    // If not, you might need to fetch all trainer exercises and filter locally (less ideal)
                    let exerciseDetail: Exercise = try await apiService.GET(endpoint: "/exercises/\(assignment.exerciseId)")
                    assignment.exercise = exerciseDetail // Populate the exercise detail
                    populatedAssignments.append(assignment)
                } catch {
                    print("AssignListVM: Failed to fetch exercise detail for \(assignment.exerciseId): \(error.localizedDescription)")
                    // Add assignment without exercise detail, or handle error differently
                    populatedAssignments.append(assignment) // Add anyway, UI can show "Exercise details unavailable"
                }
            }
            
            // Sort by sequence
            self.assignmentsWithExercises = populatedAssignments.sorted { $0.sequence < $1.sequence }
            
            print("AssignListVM: Successfully processed assignments with exercises.")
        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("AssignListVM: Error fetching assignments (APINetworkError): \(error.localizedDescription)")
            self.assignmentsWithExercises = []
        } catch {
            self.errorMessage = "An unexpected error occurred fetching assignments."
            print("AssignListVM: Unexpected error fetching assignments: \(error.localizedDescription)")
            self.assignmentsWithExercises = []
        }
        isLoading = false
    }
}
