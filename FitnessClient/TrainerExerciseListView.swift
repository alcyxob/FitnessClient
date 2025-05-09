// TrainerExerciseListView.swift
import SwiftUI

struct TrainerExerciseListView: View {
    // ViewModel is now initialized by the parent (MainTabView) or preview
    @StateObject var viewModel: TrainerExerciseListViewModel
    
    // EnvironmentObjects needed to pass to CreateExerciseView
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService // Though CreateExerciseViewModel might not need authService directly if apiService handles token

    @State private var showingCreateExerciseSheet = false

    var body: some View {
        // Use NavigationView to get a navigation bar for the title and "+" button
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading Exercises...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await viewModel.fetchTrainerExercises()
                            }
                        }
                        .padding(.top)
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if viewModel.exercises.isEmpty {
                    VStack {
                        Text("No exercises found.")
                            .font(.headline)
                            .padding(.bottom, 5)
                        Text("Tap the '+' button to create your first exercise.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        // Optional: A more prominent button if you prefer
                        // Button("Create Your First Exercise") {
                        //     showingCreateExerciseSheet = true
                        // }
                        // .padding(.top)
                        // .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.exercises) { exercise in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(exercise.name)
                                    .font(.headline)
                                
                                if let muscle = exercise.muscleGroup, !muscle.isEmpty {
                                    Text("Muscle: \(muscle)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let difficulty = exercise.difficulty, !difficulty.isEmpty {
                                    Text("Difficulty: \(difficulty)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                if let desc = exercise.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2) // Show a preview of the description
                                }
                                // TODO: Add more details or a way to navigate to a detail view
                            }
                            .padding(.vertical, 4) // Add some vertical padding to list items
                        }
                        // .onDelete(perform: deleteExercises) // Placeholder for delete
                    }
                    .listStyle(.plain) // Or .insetGrouped for a different look
                }
            }
            .navigationTitle("My Exercises")
            // .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateExerciseSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                        // Text("New") // Optional text next to the icon
                    }
                }
                // Optional: Add an EditButton for reordering/deleting if you implement those
                // ToolbarItem(placement: .navigationBarLeading) {
                //     EditButton()
                // }
            }
            .sheet(isPresented: $showingCreateExerciseSheet,
                   onDismiss: { // This closure is called when the sheet is dismissed
                        // Refresh the exercise list after the sheet is dismissed
                        // in case a new exercise was created.
                        print("CreateExerciseView sheet dismissed. Refreshing exercises.")
                        Task {
                            await viewModel.fetchTrainerExercises()
                        }
                   }) {
                // Content of the sheet: CreateExerciseView
                // Pass the APIService to CreateExerciseView's initializer
                CreateExerciseView(apiService: apiService)
                    // CreateExerciseView might also need authService if it needs user info directly,
                    // but typically ViewModel handles that.
                    // .environmentObject(authService)
            }
            .onAppear {
                // Fetch exercises when the view first appears,
                // but only if the list is currently empty (to avoid re-fetching on every tab switch
                // if data is already loaded). Or always fetch if you want fresh data.
                if viewModel.exercises.isEmpty {
                    print("TrainerExerciseListView appeared. Fetching exercises.")
                    Task {
                        await viewModel.fetchTrainerExercises()
                    }
                }
            }
        }
        // Apply userInterfaceIdiom check if you want different navigation styles for iPad
        // .navigationViewStyle(UIDevice.current.userInterfaceIdiom == .pad ? .columns : .stack)
    }

    // Placeholder for delete functionality
    // func deleteExercises(at offsets: IndexSet) {
    //     // TODO: Implement deletion logic in ViewModel and call it here
    //     // viewModel.deleteExercises(at: offsets)
    //     print("Attempting to delete exercises at: \(offsets)")
    // }
}

// Updated Preview Provider
struct TrainerExerciseListView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock services for the preview
        let mockAuthService = AuthService()
        // Simulate a logged-in trainer for the preview to enable the tab
        mockAuthService.authToken = "fake_token_for_preview"
        mockAuthService.loggedInUser = UserResponse(id: "previewTrainer", name: "Preview Trainer", email: "preview@trainer.com", role: "trainer", createdAt: Date(), clientIds: nil, trainerId: nil)

        let mockAPIService = APIService(authService: mockAuthService)
        
        // Create ViewModel instance for the preview
        let previewViewModel = TrainerExerciseListViewModel(apiService: mockAPIService, authService: mockAuthService)
        
        // Populate ViewModel with mock data for the preview to see the list
        previewViewModel.exercises = [
            Exercise(id: "1", trainerId: "previewTrainer", name: "Advanced Push Ups", description: "A challenging chest exercise focusing on core stability.", muscleGroup: "Chest, Triceps, Shoulders", executionTechnic: "Maintain a straight line from head to heels. Lower your body until your chest nearly touches the floor, then push back up.", applicability: "Any", difficulty: "Advanced", videoUrl: nil, createdAt: Date(), updatedAt: Date()),
            Exercise(id: "2", trainerId: "previewTrainer", name: "Bodyweight Squats", description: "Fundamental lower body exercise.", muscleGroup: "Quads, Glutes, Hamstrings", executionTechnic: "Stand with feet shoulder-width apart. Lower your hips back and down as if sitting in a chair, keeping your chest up and back straight. Go as low as comfortable.", applicability: "Home", difficulty: "Novice", videoUrl: nil, createdAt: Date(), updatedAt: Date())
        ]
        // To test loading state:
        // previewViewModel.isLoading = true
        // To test error state:
        // previewViewModel.errorMessage = "Failed to load (preview error)."
        // To test empty state:
        // previewViewModel.exercises = []


        // Pass the pre-configured ViewModel to the view
        return TrainerExerciseListView(viewModel: previewViewModel)
            .environmentObject(mockAuthService) // Provide environment objects
            .environmentObject(mockAPIService)
    }
}
