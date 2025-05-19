// AssignExerciseViewModel.swift
import Foundation
import SwiftUI

@MainActor
class AssignExerciseViewModel: ObservableObject {
    // Data sources for pickers
    @Published var clients: [UserResponse] = []
    @Published var exercises: [Exercise] = []

    // Selections
    @Published var selectedClientId: String? = nil
    @Published var selectedExerciseId: String? = nil
    @Published var selectedDueDate: Date? = nil // Store optional date
    @Published var includeDueDate = false // Toggle for showing DatePicker

    // Loading/Error/Success states
    @Published var isLoadingClients = false
    @Published var isLoadingExercises = false
    @Published var isAssigning = false
    @Published var errorMessage: String? = nil
    @Published var didAssignSuccessfully = false

    let workout: Workout
    private let apiService: APIService
    private let authService: AuthService // Needed for trainer ID

    var canAssign: Bool {
        // Enable button only if a client and exercise are selected
        selectedClientId != nil && selectedExerciseId != nil && !isAssigning
    }

    init(workout: Workout, apiService: APIService, authService: AuthService) {
        self.workout = workout
        self.apiService = apiService
        self.authService = authService
        print("AssignListVM: Initialized for workout: \(workout.name) (\(workout.id))")
    }

    // --- Data Fetching ---
    func loadInitialData() async {
        // Don't reload if already loaded, unless refresh is needed
        guard clients.isEmpty || exercises.isEmpty else { return }
        
        print("AssignVM: Loading initial client and exercise data...")
        // Reset states
        isLoadingClients = true
        isLoadingExercises = true
        errorMessage = nil
        didAssignSuccessfully = false

        async let clientsTask = fetchClients()
        async let exercisesTask = fetchExercises()

        // Wait for both fetches to complete
        _ = await [clientsTask, exercisesTask]

        isLoadingClients = false
        isLoadingExercises = false
        print("AssignVM: Initial data loading complete.")
    }

    private func fetchClients() async {
        isLoadingClients = true
        do {
            let fetchedClients: [UserResponse] = try await apiService.GET(endpoint: "/trainer/clients")
            self.clients = fetchedClients
        } catch {
            print("AssignVM: Error fetching clients: \(error.localizedDescription)")
            // Set specific error or ignore if exercises load?
            self.errorMessage = "Could not load clients: \(error.localizedDescription)"
        }
        isLoadingClients = false
    }

    private func fetchExercises() async {
        isLoadingExercises = true
         do {
            let fetchedExercises: [Exercise] = try await apiService.GET(endpoint: "/exercises")
            self.exercises = fetchedExercises
        } catch {
            print("AssignVM: Error fetching exercises: \(error.localizedDescription)")
            self.errorMessage = "Could not load exercises: \(error.localizedDescription)"
        }
         isLoadingExercises = false
    }

    // --- Assignment ---
    func assignExercise() async {
        guard let clientId = selectedClientId, let exerciseId = selectedExerciseId else {
            errorMessage = "Please select both a client and an exercise."
            return
        }

        print("AssignVM: Assigning exercise \(exerciseId) to client \(clientId)")
        isAssigning = true
        errorMessage = nil
        didAssignSuccessfully = false

        let payload = AssignExercisePayload(
            clientId: clientId,
            exerciseId: exerciseId,
            dueDate: includeDueDate ? selectedDueDate : nil // Only include date if toggle is on
        )

        do {
            let createdAssignment: Assignment = try await apiService.POST(endpoint: "/trainer/assignments", body: payload)
            print("AssignVM: Successfully created assignment ID: \(createdAssignment.id)")
            isAssigning = false
            didAssignSuccessfully = true // Signal success

        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("AssignVM Error assigning exercise (APINetworkError): \(error.localizedDescription)")
            isAssigning = false
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("AssignVM Unexpected error assigning exercise: \(error.localizedDescription)")
            isAssigning = false
        }
    }
    
    func fetchVideoDownloadURL(for assignment: Assignment) async -> URL? {
        guard let trainerId = authService.loggedInUser?.id else { // Assuming authService is a property or passed to init
            print("AssignListVM (Trainer): Trainer ID not found for fetching video URL.")
            self.errorMessage = "Authentication error." // Or a more general error
            return nil
        }
        // Ensure the trainer actually owns this assignment's workout
        // This check is also in the backend, but good for client-side quick fail
        if self.workout.trainerId != trainerId {
             print("AssignListVM (Trainer): Trainer does not own this workout (\(workout.id)) to fetch video URL for assignment \(assignment.id).")
             self.errorMessage = "Access Denied."
             return nil
        }

        print("AssignListVM (Trainer): Fetching video download URL for assignment ID: \(assignment.id)")
        // isLoadingVideoForAssignmentId = assignment.id // Optional: per-item loading state
        self.errorMessage = nil // Clear previous general errors

        let endpoint = "/trainer/assignments/\(assignment.id)/video-download-url"
        
        do {
            let response: VideoDownloadURLResponse = try await apiService.GET(endpoint: endpoint) // Expects VideoDownloadURLResponse DTO
            print("AssignListVM (Trainer): Received video download URL.")
            // isLoadingVideoForAssignmentId = nil
            return URL(string: response.downloadUrl)
        } catch let error as APINetworkError {
            self.errorMessage = "Could not get video URL: \(error.localizedDescription)"
            print("AssignListVM (Trainer): Error fetching video URL (APINetworkError): \(error.localizedDescription)")
        } catch {
            self.errorMessage = "An unexpected error occurred getting video URL."
            print("AssignListVM (Trainer): Unexpected error fetching video URL: \(error.localizedDescription)")
        }
        // isLoadingVideoForAssignmentId = nil
        return nil
    }
}
