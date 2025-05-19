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
    private let authService: AuthService
    // No direct need for authService if apiService handles token and trainerID is on workout for context

    init(workout: Workout, apiService: APIService, authService: AuthService) {
        self.workout = workout
        self.apiService = apiService
        self.authService = authService
        print("AssignListVM: Initialized for workout: \(workout.name) with authService.")
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
    
    // Method to get the video download URL (Trainer's context)
    func fetchVideoDownloadURL(for assignment: Assignment) async -> URL? {
        // Check 1: Ensure the logged-in user is a trainer from authService
        guard let currentUser = self.authService.loggedInUser, currentUser.role == "trainer" else {
            print("AssignListVM: Current user is not a trainer or not logged in. Cannot fetch video URL.")
            // Set an error message specific to this action, not the general list errorMessage
            // self.videoFetchError = "Not authorized as trainer." // Example for a specific error property
            return nil
        }

        // Check 2: The workout associated with THIS ViewModel must belong to the current trainer
        if self.workout.trainerId != currentUser.id {
             print("AssignListVM: Trainer \(currentUser.id) does not own this workout (\(self.workout.id)). Cannot fetch video URL for assignment \(assignment.id).")
             // self.videoFetchError = "Access denied to this workout."
             return nil
        }
        
        // Check 3: The assignment's workout ID must match this ViewModel's workout ID (sanity check)
        if assignment.workoutId != self.workout.id {
            print("AssignListVM: Assignment \(assignment.id) does not belong to workout \(self.workout.id).")
            // self.videoFetchError = "Assignment mismatch."
            return nil
        }


        print("AssignListVM (Trainer): Fetching video download URL for assignment ID: \(assignment.id)")
        // Note: errorMessage on the ViewModel is general for the list.
        // If this specific action fails, you might want a separate error state for the video button.
        // For now, it will overwrite the general errorMessage.

        let endpoint = "/trainer/assignments/\(assignment.id)/video-download-url"
        
        do {
            // This call should use the trainer's token via apiService
            let response: VideoDownloadURLResponse = try await apiService.GET(endpoint: endpoint)
            print("AssignListVM (Trainer): Received video download URL: \(response.downloadUrl)")
            return URL(string: response.downloadUrl)
        } catch let error as APINetworkError {
            // Set general error message for now
            self.errorMessage = "Could not get video URL: \(error.localizedDescription)"
            print("AssignListVM (Trainer): Error fetching video URL (APINetworkError): \(self.errorMessage ?? "")")
        } catch {
            self.errorMessage = "An unexpected error occurred getting video URL."
            print("AssignListVM (Trainer): Unexpected error fetching video URL: \(self.errorMessage ?? "")")
        }
        return nil
    }
    
    // --- Delete Assignment ---
    func deleteAssignment(assignmentId: String) async -> Bool {
        guard let currentTrainerId = authService.loggedInUser?.id else {
            errorMessage = "Authentication error."
            return false
        }
        // Ensure this trainer owns the workout this assignment belongs to
        if workout.trainerId != currentTrainerId {
            errorMessage = "Access Denied: You do not own this workout."
            return false
        }
        // The backend will also check if assignmentId belongs to workoutId

        print("AssignListVM (Trainer): Deleting assignment ID: \(assignmentId) from workout \(workout.id)")
        isLoading = true // Use general loading flag or a specific one for delete
        let previousErrorMessage = errorMessage
        errorMessage = nil

        // Endpoint: /trainer/workouts/{workoutId}/assignments/{assignmentId}
        let endpoint = "/trainer/workouts/\(workout.id)/assignments/\(assignmentId)"

        do {
            try await apiService.DELETE(endpoint: endpoint)
            print("AssignListVM (Trainer): Successfully deleted assignment \(assignmentId)")
            
            self.assignmentsWithExercises.removeAll { $0.id == assignmentId } // Optimistic UI update
            if assignmentsWithExercises.isEmpty {
                // errorMessage = "No exercises assigned to this workout yet."
            }
            isLoading = false
            return true
        } catch let error as APINetworkError {
            self.errorMessage = "Delete failed: \(error.localizedDescription)"
            print("AssignListVM (Trainer): Error deleting assignment (APINetworkError): \(error.localizedDescription)")
        } catch {
            self.errorMessage = "An unexpected error occurred while deleting assignment."
            print("AssignListVM (Trainer): Unexpected error deleting assignment: \(error.localizedDescription)")
        }
        if self.errorMessage != nil && previousErrorMessage != nil { /* ... restore error ... */ }
        isLoading = false
        return false
    }
}
